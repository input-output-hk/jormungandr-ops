#!/usr/bin/env nix-shell
#!nix-shell -i crystal -p crystal

require "json"
require "option_parser"
require "file_utils"

class Deployer
  class Config
    property? delete_state = false,
              skip_backup = false,
              skip_nixops = false,
              skip_copy = false,
              skip_healthcheck = false,
              restore_backup = false
    property since_time : String = 6.hours.ago.to_s,
             until_time : String = Time.utc.to_s
  end

  @nodes  = [] of Node::Any
  @config = Config.new

  def parse_options
    config = @config

    OptionParser.parse! do |parser|
      parser.banner = "Usage: ./scripts/dpl-qa.cr [arguments]"

      parser.on "--delete-state", "Delete state on all nodes" { config.delete_state = true }
      parser.on "--skip-backup", "Don't backup state" { config.skip_backup = true }
      parser.on "--skip-nixops", "Don't run nixops deploy" { config.skip_nixops = true }
      parser.on "--skip-copy", "Don't run nixops copy" { config.skip_copy = true }
      parser.on "--skip-healthcheck", "Don't wait for healthcheck to pass" { config.skip_healthcheck = true }
      parser.on "--restore-backup", "restore backup before start" { config.restore_backup = true }
      parser.on "--all", "Deploy all nodes" { nodes = all_nodes }
      parser.on "--stakes", "Deploy stake nodes" { nodes = stakes }
      parser.on "--relays", "Deploy relays nodes" { nodes = relays }
      parser.on "--since=TIME", "Time from which logs are backed up" { |time| config.since_time = time }
      parser.on "--until=TIME", "Time until which logs are backed up" { |time| config.until_time = time }

      parser.invalid_option do |flag|
        STDERR.puts "ERROR: #{flag} is not a valid option."
        STDERR.puts parser
        exit(1)
      end

      parser.unknown_args { |args|
        @nodes += all_nodes.select { |n| args.includes?(n.name) }
      }
    end
  end

  def deploy
    parse_options
    deploy @nodes
  end

  def deploy(nodes_to_deploy : Array(Node::Any))
    copy_only
    backup_all
    restore_backup_all

    puts "deploying to: ", nodes_to_deploy.map(&.name).join(" ")

    if @config.skip_healthcheck?
      nodes_to_deploy.each &.deploy(nil, @config)
      return
    end

    nodes_to_deploy.each do |node|
      highest = find_highest_stake(node)
      stake = highest[:node]
      height = highest[:height]

      raise "No suitable stable stake node found to sync with" unless stake

      puts "#{stake.name} is at #{height} blocks"
      node.deploy(stake, @config)
    end
  end

  def find_highest_stake(current : Node::Any)
    result_chan = Channel({Node, JCLI::NodeStats::Result}).new

    all_nodes.each do |node|
      spawn {
        result_chan.send({node, node.statistics})
      }
    end

    Fiber.yield

    received = all_nodes.map { |node| result_chan.receive }

    # NOTE: select multiple highest nodes to avoid unneeded deploys
    highest_stake_block = 0_u64
    highest_stake = nil

    received.each { |(node, statistics)|
      case node
      when Node::Stake
        next if current == node
        uptime = statistics.try(&.uptime)
        next unless uptime && uptime > (60 * 3) # skip utterly unstable nodes

        height = statistics.try(&.lastBlockHeight).try(&.to_u64)
        if height && height > highest_stake_block
          highest_stake_block = height
          highest_stake = node
        end
      end
    }

    {node: highest_stake, height: highest_stake_block}
  end

  def copy_only
    return if @config.skip_copy?
    system("nixops", ["deploy", "--copy-only"]) || raise("Failed copying")
  end

  def backup_all
    return if @config.skip_backup?

    results = Channel(Node::Name).new
    all_nodes.each do |node|
      spawn {
        node.backup
        results.send(node.name)
      }
    end

    Fiber.yield

    all_nodes.each { |node| results.receive }
  end

  def restore_backup_all
    return unless @config.restore_backup?

    results = Channel(Node::Name).new
    all_nodes.each do |node|
      spawn do
        node.restore_backup
        results.send node.name
      end

      Fiber.yield
      all_nodes.each{|node| results.receive }
    end
  end

  def all_nodes : Array(Node::Any)
    relays + stakes
  end

  def relays : Array(Node)
    RELAYS.map { |name| Node::Relay.new(name, @config).as(Node) }
  end

  def stakes : Array(Node)
    STAKES.map { |name| Node::Stake.new(name, @config).as(Node) }
  end

  def node_names(node : String) : Node::Names
    NODE_NAMES
  end

  # TODO: optimize
  RELAYS = Array(String).from_json(`nix eval --json '((import ./scripts/nodes.nix).relaysNames)'`)
  STAKES = Array(String).from_json(`nix eval --json '((import ./scripts/nodes.nix).stakesNames)'`)
end

abstract class Node
  class Relay < Node; end

  class Stake < Node; end

  alias Any = Relay | Stake

  TIME = Time.utc

  alias Name = String
  alias Names = Array(Name)

  getter name : Name
  getter silent : Bool = false
  getter config : Deployer::Config

  def initialize(@name, @config)
  end

  def deploy(highest_stake : Nil, config)
    cleanup if config.delete_state?

    if config.skip_nixops?
      start_jormungandr
    else
      nixops_deploy
    end
  end

  def deploy(highest_stake : Node, config)
    cleanup if config.delete_state?

    if config.skip_nixops?
      start_jormungandr
    else
      nixops_deploy
    end

    healthcheck(highest_stake) unless config.skip_healthcheck?
  end

  def backup
    backup_db
    backup_log
  end

  def backup_log
    return if File.exists?(backup_log_file)

    FileUtils.mkdir_p backup_dir

    args = ["ssh", @name, "--", "journalctl -o verbose -u jormungandr --since #{config.since_time} --until #{config.until_time}"]
    Process.run "nixops", args: args do |process|
      File.open(backup_log_file, "w") do |log|
        IO.copy(process.output, log)
      end
    end
  end

  def backup_db
    return if File.exists?(backup_db_file)

    FileUtils.mkdir_p backup_dir

    tmp = TIME.to_s("/var/lib/jormungandr/%F-%T.sqlite")
    ssh "sqlite3 -readonly /var/lib/jormungandr/blocks.sqlite '.backup #{tmp}'"
    nixops "scp", "--from", @name, tmp, backup_db_file
  end

  def restore_backup
    puts "restoring last backup"

    ssh "mkdir", "-p", "/var/lib/jormungandr"
    nixops "scp", "--to", @name, backup_db_file, "/var/lib/jormungandr/blocks.sqlite"
    ssh "chown", "-R", "jormungandr:jormungandr", "/var/lib/jormungandr/blocks.sqlite"
  end

  def cleanup
    log "Deleting state"
    ssh "systemctl", "stop", "jormungandr"
    ssh "rm", "-rf", "/var/lib/jormungandr"
  end

  def nixops_deploy
    nixops "deploy", "--include", @name
  end

  def start_jormungandr
    ssh "systemctl", "start", "jormungandr"
  end

  def healthcheck(idol_node : Node::Stake)
    STDOUT.sync = true

    bootstrapping = true

    loop do
      idol_stats = idol_node.statistics.as(JCLI::NodeStats::Running)

      case node_stats = statistics
      when JCLI::NodeStats::Running
        bootstrapping = false
        print "\r#{@name} Running... height: #{node_stats.lastBlockHeight}/#{idol_stats.lastBlockHeight}"
        print " " * 30
      when JCLI::NodeStats::Bootstrapping
        raise "Node failed, returned to bootstrapping" unless bootstrapping
        print "\r#{@name} Bootstrapping..."
        print " " * 30
      else
        raise "Unknown state: #{node_stats.inspect}"
      end

      break if node_stats.lastBlockHeight == idol_stats.lastBlockHeight
      sleep 5
    end
  end

  def ssh(*args : String)
    nixops("ssh", @name, "--", *args)
  end

  # TODO: move this into a common location
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

  def backup_dir
    time = TIME.to_s("%F-%H")
    "backup/#{time}"
  end

  def backup_db_file
    File.join(backup_dir, "#{@name}.sqlite")
  end

  def backup_log_file
    File.join(backup_dir, "#{@name}.log")
  end

  def statistics
    silently do
      result = ssh "jcli", "rest", "v0", "node", "stats", "get", "--output-format", "json"
      JCLI::NodeStats.parse(result.to_s)
    end
  rescue
    nil
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
    end

    class Bootstrapping
      JSON.mapping(state: String)

      def lastBlockHeight
        "0"
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
    end
  end
end

Deployer.new.deploy

