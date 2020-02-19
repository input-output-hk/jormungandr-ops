#!/usr/bin/env nix-shell
#!nix-shell -i crystal -p crystal

require "json"
require "file_utils"

class CatHerder
  MAX_HEIGHT_DIFFERENCE     = 50
  TIME_BETWEEN_ITERATIONS   = 1.minute
  TIME_TO_WAIT_AFTER_DEPLOY = 10.seconds
  RELAYS                    = Array(String).from_json(`nix eval --json '((import ./scripts/nodes.nix).relaysNames)'`)
  STAKES                    = Array(String).from_json(`nix eval --json '((import ./scripts/nodes.nix).stakesNames)'`)

  property silent = false

  def start
    loop do
      iterate
      sleep TIME_BETWEEN_ITERATIONS
    end
  end

  def iterate
    puts "Checking node stats ..."

    the_nodes = nodes
    dead = the_nodes[:dead]
    running = the_nodes[:running]
    by_height = running.sort_by(&.stats.lastBlockHeight.to_u64)

    raise "Nobody is running or has blocks?" unless by_height.size > 0
    best = by_height.last.not_nil!.stats.lastBlockHeight.to_u64

    behind = by_height.select do |node|
      node.stats.not_nil!.lastBlockHeight.to_u64 < (best - MAX_HEIGHT_DIFFERENCE)
    end

    to_cull = dead + behind.first(8)

    oldest = running.sort_by(&.stats.uptime).last
    oldest_uptime = Time::Span.new(0, 0, oldest.stats.uptime)
    if oldest_uptime > 3.hours
      puts "#{oldest.name} has reached the ripe age of #{oldest_uptime}, sending it into retirement"
      to_cull << oldest
    end
    # return if to_cull.empty?

    dead.each do |node|
      puts "Culling #{node.name} because it's dead"
    end

    behind.each do |node|
      delta = best - node.stats.not_nil!.lastBlockHeight.to_u64
      puts "Culling #{node.name} because it's #{delta} blocks behind"
    end

    puts "Fetching backup from block height leader..."

    backup_best by_height.last.not_nil!.name

    trusted = by_height.select do |node|
      node.stats.lastBlockHeight.to_u64 > (best - 1)
    end

    trusted_names = trusted.map(&.name)
    puts "New trusted peers: #{trusted_names.join(" ")}"
    File.write("trusted.json", trusted_names.to_pretty_json)

    cull! to_cull
  rescue ex
    puts ex
  end

  def backup_best(best_name)
    puts "backing up db from #{best_name} to blocks.sqlite.bak"
    Process.run("nixops", ["ssh", best_name, "--", <<-SSH], error: STDERR)
      sqlite3 -readonly /var/lib/jormungandr/blocks.sqlite '.backup blocks.sqlite.bak'
    SSH

    Process.run(
      "nixops",
      ["scp", "--from", best_name, "blocks.sqlite.bak", "blocks.sqlite.bak"],
      error: STDERR)
  end

  def nodes
    node_ch = Channel(Node).new
    node_names.each { |name| spawn { node_ch.send(Node.init(name)) } }

    running = [] of Node::Running
    dead = [] of Node::Dead
    bootstrapping = [] of Node::Bootstrapping

    node_names.each do
      case n = node_ch.receive
      when Node::Running
        running << n
      when Node::Bootstrapping
        bootstrapping << n
      when Node::Dead
        dead << n
      end
    end

    {
      running:       running,
      dead:          dead,
      bootstrapping: bootstrapping,
    }
  end

  def cull!(nodes)
    names = nodes.map(&.name)
    # names.delete "relay-pools-a-1"
    # names = ["relay-pools-a-1"]

    return if names.empty?

    puts "Culling #{names.join(" ")} in 10 seconds"
    sleep 10

    node_ch = Channel(Bool).new

    names.each do |name|
      spawn do
        Process.run(
          "nixops",
          ["scp", "--to", name, "blocks.sqlite.bak", "blocks.sqlite.bak"],
          error: STDERR)
        node_ch.send true
      end
    end

    names.each { |n| node_ch.receive }

    Process.run(
      "nixops",
      ["ssh-for-each", "-p", "--include"] + names + ["--", <<-SSH], error: STDERR)
      systemctl stop jormungandr && \
      rm -rf /var/lib/jormungandr/blocks.sqlite* || true && \
      cp blocks.sqlite.bak /var/lib/jormungandr/blocks.sqlite && \
      chown jormungandr:jormungandr -R /var/lib/jormungandr
    SSH

    Process.run(
      "nixops",
      ["deploy", "--include"] + names,
      error: STDERR,
      env: {"ROLLBACK_ENABLED" => "false"})
    sleep TIME_TO_WAIT_AFTER_DEPLOY
  end

  def node_names
    RELAYS + STAKES
  end

  abstract class Node
    class Running < Node
      getter stats : JCLI::NodeStats::Running
      getter name : String

      def initialize(@name, @stats)
      end
    end

    class Bootstrapping < Node
      getter stats : JCLI::NodeStats::Bootstrapping
      getter name : String

      def initialize(@name, @stats)
      end
    end

    class Dead < Node
      getter stats : Nil
      getter name : String

      def initialize(@name, @stats)
      end
    end

    def self.init(name) : Running | Bootstrapping | Dead
      output = IO::Memory.new
      status = Process.run("nixops", [
        "ssh", name, "timeout", "1", "jcli", "rest", "v0", "node", "stats", "get", "--output-format", "json",
      ], output: output, error: STDERR)

      case status.exit_status
      when 31744
        puts "Dead: #{name} timed out when getting node stats"
        return Dead.new(name, nil)
      when 0
      else
        puts "Dead: #{name} returned with #{status.exit_status} when getting node stats"
        return Dead.new(name, nil)
      end

      case stats = JCLI::NodeStats.parse(output.to_s)
      when JCLI::NodeStats::Running
        receive_queue = recvq(name)
        if receive_queue > 100
          puts "Dead: #{name} receive queue is #{receive_queue}"
          Dead.new(name, nil)
        else
          Running.new(name, stats)
        end
      when JCLI::NodeStats::Bootstrapping
        last_log = last_log_time(name)
        attempts = bootstrap_attempts(name)

        if last_log < 10.minutes.ago
          puts "Dead: #{name} had last log at #{last_log}"
          Dead.new(name, nil)
        elsif attempts > 50
          puts "Dead: #{name} attempted to bootstrap #{attempts} times"
          Dead.new(name, nil)
        else
          puts "Boot: #{name} is still bootstrapping"
          Bootstrapping.new(name, stats)
        end
      else
        puts "Dead: #{name} couldn't get any node stats"
        Dead.new(name, nil)
      end
    end

    def self.last_log_time(name)
      output = IO::Memory.new
      Process.run("nixops", [
        "ssh", name, "--", "journalctl", "-u", "jormungandr", "-o", "json", "-n", "1",
      ], output: output, error: STDERR)

      stamp = JSON.parse(output.to_s)["_SOURCE_REALTIME_TIMESTAMP"]?
      return Time.unix 0 unless stamp
      Time.unix((stamp.as_s.to_i64 / 1000000).to_i)
    end

    def self.recvq(name)
      output = IO::Memory.new
      Process.run("nixops", [
        "ssh", name, "--", "ss", "-plntH", "'( sport = :3000 )'",
      ], output: output, error: STDERR)
      num = output.to_s.split[1]?
      num ? num.to_i : 0
    end

    def self.bootstrap_attempts(name)
      output = IO::Memory.new
      Process.run("nixops", [
        "ssh", name, "--", "journalctl", "-u", "jormungandr", "-o", "json", "-n", "10",
      ], output: output, error: STDERR)

      output.to_s.each_line do |line|
        json = JSON.parse(line)
        next unless json["MESSAGE"].as_s =~ /^bootstrap attempt #(\d+) failed/
        return $1.to_i
      end

      return 0
    end
  end
end

module JCLI
  class NodeStats
    alias Result = Running | Bootstrapping | Nil

    # TODO: simplify this when 0.32 is out
    def self.parse(input : String) : Result
      case bootstrapping = Bootstrapping.from_json(input)
      when .state
        case bootstrapping.state
        when "Running"
          Running.from_json(input)
        when "Bootstrapping"
          bootstrapping
        end
      end
    rescue e
      pp! e
      nil
    end

    class StuckBootstrapping
      def bootstrapping?
        true
      end

      def stuck?
        true
      end
    end

    class Bootstrapping
      JSON.mapping(state: String)

      def bootstrapping?
        true
      end

      def stuck?
        false
      end
    end

    class Running
      JSON.mapping(
        blockRecvCnt: UInt64,
        lastBlockDate: String,
        lastBlockFees: UInt64,
        lastBlockHash: String,
        lastBlockHeight: String,
        lastBlockSum: UInt64,
        lastBlockTime: Time?,
        lastBlockTx: UInt64,
        state: String,
        txRecvCnt: UInt64,
        uptime: UInt64
      )

      def lastBlockHeight : UInt64
        @lastBlockHeight.to_u64
      end

      def bootstrapping?
        false
      end
    end
  end
end

CatHerder.new.start
