#!/usr/bin/env nix-shell
#!nix-shell -i ruby -p ruby openssl

require 'json'
require 'open3'
require 'optparse'

keys = {}
path = 'secrets/jormungandr-public-ids.json'
options = { force: false, input: path, output: path }

OptionParser.new{|o|
  o.banner = "Usage: ./#{__FILE__} [options]"
  o.on('-f', '--force'){|v| options[:force] = v }
  o.on('-i=FILE', '--input=FILE'){|v| options[:input] = v }
  o.on('-o=FILE', '--output=FILE'){|v| options[:output] = v }
}.parse!

if File.exist?(options[:input])
  keys = JSON.parse(File.read(options[:input]))
end

parse = ->(_, so, se, _){
  stderr = se.read
  puts stderr unless stderr.empty?
  machines = JSON.parse(so.read)
  longest = machines.max_by(&:size).size

  machines.sort.each do |name|
    next if keys.key?(name)

    key = `openssl rand -hex 24`.strip
    warn "new key: %-#{longest}s -> %s" % [name, key]
    keys[name] = key
  end
}

Open3.popen3('nix', 'eval', '--json', <<NIX, &parse)
(
with builtins;

let
  globals = import ./globals.nix;
  nixopsDeployment = getEnv("NIXOPS_DEPLOYMENT");
  deployment = import (./deployments + "/${nixopsDeployment}.nix") {};

  ignore = [
    "resources"
    "monitoring"
    "network"
  ];
in attrNames (removeAttrs deployment ignore)
)
NIX

output = JSON.pretty_unparse(keys)
puts output

if File.exist?(options[:output])
  if options[:force]
    File.write(options[:output], output)
  else
    warn "run with --force to overwrite #{options[:output]}"
  end
else
  File.write(options[:output], output)
end
