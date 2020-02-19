require "json"
require "file_utils"

ENV["RUST_BACKTRACE"] = "1"

def cat_beating
  relays = Array(String).from_json(`nix eval --json '((import ./scripts/nodes.nix).relaysNames)'`)
  nodes = Hash(String, String).new

  `nixops info --no-eval`.each_line do |line|
    parts = line.split("|").map(&.strip) - [""]
    next unless parts[2]? =~ /^ec2 /
    name = parts[0]
    next unless relays.includes?(name)
    next if name =~ /^explorer/
    ip = parts[4]
    nodes[name] = ip
  end

  public_ids = JSON.parse(File.read("secrets/jormungandr-public-ids.json")).as_h

  results = Channel({String, Bool}).new

  FileUtils.rm_rf "tmp/cat-beater"

  nodes.each_with_index do |(node, ip), index|
    spawn do
      dir = "tmp/cat-beater/#{node}"
      FileUtils.mkdir_p dir
      config = File.expand_path(File.join(dir, "config.json"))

      port = 3000 + index

      File.write(config, {
        "log" => [
          {
            "format" => "plain",
            "level"  => "info",
            "output" => "stdout",
          },
        ],
        "p2p" => {
          "listen_address" => "/ip4/0.0.0.0/tcp/#{port}",
          "trusted_peers"  => [
            {
              "address" => "/ip4/#{ip}/tcp/#{port}",
              "id"      => public_ids[node].as_s,
            },
          ],
        },
      }.to_pretty_json)

      # FileUtils.cp("blocks.sqlite.bak", File.expand_path(File.join(dir, "blocks.sqlite")))

      Process.run("jormungandr", [
        "--config", config,
        "--storage", dir,
        "--genesis-block", File.expand_path("block-0.bin"),
      ]) do |process|
        spawn do
          sleep 30.minutes
          if process.exists?
            spawn results.send({node, false})
            process.kill
          end
        end

        while line = process.output.gets
          puts "%20s : %s" % [node, line]

          case line
          when /unable to reach peer for initial bootstrap/,
               /initial bootstrap failed/
            spawn results.send({node, false})
            process.kill
          when /initial bootstrap completed/
            spawn results.send({node, true})
            process.kill
          end
        end
      end
    end
  end

  sick = [] of String
  healthy = [] of String

  nodes.each do |_, _|
    node, result = results.receive

    if result
      healthy << node
    else
      sick << node
    end
  end

  if healthy.any?
    puts "healthy nodes: #{healthy.join(" ")}"
  end

  if sick.any?
    really_sick = [] of String
    sick.each do |node|
      output = IO::Memory.new
      Process.run "nixops", ["ssh", node, "--", "jcli", "rest", "v0", "node", "stats", "get"], output: output, error: output
      next if output.to_s =~ /Bootstrapping/
      next if output.to_s =~ /failed to make a REST request/
      really_sick << node
    end

    puts "sick nodes: #{really_sick.join(" ")}"
    really_sick.shuffle.each do |node|
      puts "will restart #{node} in 10 seconds"
      sleep 10
      Process.run "nixops", ["ssh", node, "--", "systemctl", "restart", "jormungandr"]
      sleep 5.minutes
    end
  end
end

loop do
  cat_beating
  sleep 15.minutes
end
