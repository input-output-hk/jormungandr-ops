#!/usr/bin/env nix-shell
#!nix-shell -I nixpkgs=./nix -i crystal -p crystal

require "json"

filter = ARGV[0]?
unless filter
  puts "Please give a node name filter as argument"
  puts "for example to list all nodes included 'explorer' in their name do:"
  puts "./scripts/trusted-peers.cr explorer"
  exit 1
end

nodes = Hash(String, String).new

`nixops info --no-eval`.each_line do |line|
  parts = line.split("|").map(&.strip) - [""]
  next unless parts[2]? =~ /^ec2 /
  name = parts[0]
  next unless name =~ /#{filter}/
  ip = parts[4]
  nodes[name] = ip
end

public_ids = JSON.parse(File.read("secrets/jormungandr-public-ids.json")).as_h

result = Array(Hash(String, String)).new
nodes.each do |name, ip|
  result << {
    "address" => "/ip4/#{ip}/tcp/3000",
    "id"      => public_ids[name].as_s,
  }
end

puts result.to_pretty_json
