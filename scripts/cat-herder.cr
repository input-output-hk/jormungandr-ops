#!/usr/bin/env nix-shell
#!nix-shell -i crystal -p crystal

require "json"
require "file_utils"

class CatHerder
  RELAYS = Array(String).from_json(`nix eval --json '((import ./scripts/nodes.nix).relaysNames)'`)
  STAKES = Array(String).from_json(`nix eval --json '((import ./scripts/nodes.nix).stakesNames)'`)

  property silent = false

  def start
    loop do
      iterate
      sleep(10)
    end
  end

  def iterate
    time = Time.utc

    puts "Checking node stats ..."

    node_ch = Channel(Tuple(Node, JCLI::NodeStats::Result)).new
    node_names.each { |name|
      node = Node.new(name, time)
      spawn { node_ch.send({node, node.statistics}) }
    }

    nodes = node_names.map { node_ch.receive }
    alive, dead = nodes.partition{|(node, stats)| stats }
    dead_names = dead.map{|(node, stats)| node.name }

    puts "dead: #{dead_names.join(" ")}"

    ranked = alive.select{|(node, stats)|
      stats.try(&.state) == "Running"
    }.sort_by{|(node, stats)|
      stats.not_nil!.lastBlockHeight.to_u64
    }

    raise "Nobody is running or has blocks?" unless ranked.size > 0
    best = ranked.last[1].not_nil!.lastBlockHeight.to_u64

    candidates = ranked.select do |(node, stats)|
      stats.not_nil!.lastBlockHeight.to_u64 < (best - 10)
    end

    return if dead.empty? && candidates.empty?

    trusted = ranked.select do |(node, stats)|
      s = stats.not_nil!
      s.lastBlockHeight.to_u64 > (best - 1) && s.uptime > 30.minutes.to_i
    end

    if trusted.any?{|(node, stats)| node.name =~ /relay/ }
      trusted.reject!{|(node, stats)| node.name !~ /relay/ }
    end

    trusted_names = trusted.map{|(node, stats)| node.name }
    puts "New trusted peers: #{trusted_names.join("  ")}"
    File.write("trusted.json", trusted_names.to_pretty_json)

    # backup_file = ranked.last[0].backup
    backup_file = nil

    dead_chan = Channel(Nil).new

    dead.shuffle.first(5).each do |(node, stats)|
      spawn {
        node.cull!(backup_file)
        dead_chan.send nil
      }
    end

    dead.each{ dead_chan.receive }

    candidates = candidates.first(8)
    puts "death row candidates: #{candidates.map{|(n, s)| n.name }.join(" ")}"

    cand_chan = Channel(Nil).new

    candidates.each do |(node, stats)|
      spawn {
        node.cull!(backup_file)
        cand_chan.send nil
      }
    end

    candidates.each { cand_chan.receive }
  rescue ex
    puts ex
  end

  def node_names
    RELAYS + STAKES
  end

  class Node
    property name : String
    getter time : Time
    getter restart_counter : UInt64
    getter last_restart : Time | Nil

    def initialize(@name, @time);
      @restart_counter = 1
      @last_restart = nil
    end

    def backup
      return backup_db_file if File.file?(backup_db_file)
      FileUtils.mkdir_p(backup_dir)
      tmp = time.to_s("/var/lib/jormungandr/%F-%T-#{@name}.sqlite")
      ssh "sqlite3 -readonly /var/lib/jormungandr/blocks.sqlite '.backup #{tmp}'"
      nixops "scp", "--from", @name, tmp, backup_db_file
      backup_db_file
    end

    def cull!(backup)
      puts "Culling #{@name}, restarts: #{restart_counter}, last restart: #{last_restart.to_s}"

      sleep 5

      if restart_counter % 4 == 0
        ssh <<-SHELL
          systemctl stop jormungandr;
          rm -rf /var/lib/jormungandr;
        SHELL
      else
        ssh "systemctl stop jormungandr"
      end

      nixops "deploy", "--include", @name

      # ssh "systemctl start jormungandr"

      sleep 2.minutes

      # mkdir -p /var/lib/jormungandr

      # nixops "scp", "--to", @name, backup, "/var/lib/jormungandr/blocks.sqlite"

      # ssh <<-SHELL
      #   chown -R jormungandr:jormungandr /var/lib/jormungandr;
      #   systemctl start jormungandr
      # SHELL
    ensure
      @last_restart = Time.now
      @restart_counter += 1
    end

    def backup_dir
      t = time.to_s("%F-%H")
      "backup/#{t}"
    end

    def backup_db_file
      FileUtils.mkdir_p(backup_dir)
      File.join(backup_dir, "#{@name}.sqlite")
    end

    def statistics
      silently do
        result = ssh "timeout", "0.5", "jcli", "rest", "v0", "node", "stats", "get", "--output-format", "json"
        JCLI::NodeStats.parse(result.to_s)
      end
    rescue
      nil
    end

    def ssh(*args : String)
      nixops("ssh", @name, "--", *args)
    end

    def nixops(*args : String)
      pretty_log("nixops", *args)

      result, tee = make_tee
      status = Process.run("nixops", args: args, output: tee, error: tee)
      raise "failed with #{status.exit_status}" unless status.success?
      result
    end

    def make_tee
      result = IO::Memory.new

      if @silent
        [result, result]
      else
        [result, IO::MultiWriter.new(result, STDOUT)]
      end
    end

    def pretty_log(*args)
      pretty = args.to_a.map { |arg|
        case arg
        when Array(String)
          "'#{arg.join(" ")}'"
        else
          arg
        end
      }.join(" ")

      log pretty
    end

    def warn(msg)
      STDERR.puts msg
    end

    def log(msg)
      puts "#{@name} : #{msg}" unless @silent
    end

    def silently
      @silent = true
      yield
    ensure
      @silent = false
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
        else
          bootstrapping
        end
      else
        nil
      end
    rescue e
      pp! e
      nil
    end

    class Bootstrapping
      JSON.mapping(state: String)

      def lastBlockHeight
        0_u64
      end

      def uptime
        0_u64
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
    end
  end
end

CatHerder.new.start
