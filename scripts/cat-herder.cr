#!/usr/bin/env nix-shell
# !nix-shell -i crystal -p crystal

require "json"
require "file_utils"

class CatHerder
  RELAYS = Array(String).from_json(`nix eval --json '((import ./scripts/nodes.nix).relaysNames)'`)
  STAKES = Array(String).from_json(`nix eval --json '((import ./scripts/nodes.nix).stakesNames)'`)

  property silent = false

  def start
    loop do
      iterate
      sleep(60 * 5)
    end
  end

  def iterate
    time = Time.utc
    nodes = node_names.map { |name|
      node = Node.new(name, time)
      {node, node.statistics}
    }

    alive, dead = nodes.partition{|(node, stats)| stats }

    ranked = alive.sort_by{|(node, stats)| stats.not_nil!.lastBlockHeight.to_u64 }
    best = ranked.last[1].not_nil!.lastBlockHeight.to_u64

    candidates = ranked.select do |(node, stats)|
      stats.not_nil!.lastBlockHeight.to_u64 < (best - 50)
    end

    return if dead.empty? && candidates.empty?

    # backup_file = ranked.last[0].backup
    backup_file = nil

    dead.each do |(node, stats)|
      puts "Dead node #{node.name}"
      node.cull!(backup_file)
      return
    end

    candidates.shuffle.first(3).each do |(node, stats)|
      puts "Stuck node #{node.name}"
      node.cull!(backup_file)
    end
  rescue ex
    puts "hit error while iterating"
    puts ex
  end

  def node_names
    RELAYS + STAKES
  end

  class Node
    property name : String
    getter time : Time

    def initialize(@name, @time);
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
      puts "culling #{@name}, may it fare better in its next life!"

      ssh <<-SHELL
        systemctl stop jormungandr;
        rm -rf /var/lib/jormungandr;
        mkdir -p /var/lib/jormungandr
      SHELL

      # nixops "scp", "--to", @name, backup, "/var/lib/jormungandr/blocks.sqlite"

      ssh <<-SHELL
        chown -R jormungandr:jormungandr /var/lib/jormungandr;
        systemctl start jormungandr
      SHELL
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
        result = ssh "jcli", "rest", "v0", "node", "stats", "get", "--output-format", "json"
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
