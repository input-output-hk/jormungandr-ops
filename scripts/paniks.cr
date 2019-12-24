#!/usr/bin/env nix-shell
#!nix-shell -p crystal -i crystal

nodes = `nix eval --raw '((import ./scripts/nodes.nix).allStrings)'`.split
nodes.reject!{|n| n =~ /^io(p|h)\d+$/ }

outputs = Channel(String).new

nodes.each do |node|
  spawn do
    if File.file?("panics/#{node}.json")
      `nixops scp --to #{node} panik.rb panik.rb`
      result = `nixops ssh #{node} -- 'chmod +x panik.rb; ./panik.rb'`.strip
      File.write("panics/#{node}.json", result)
      outputs.send result
    else
      outputs.send File.read("panics/#{node}.json")
    end
  end
end

results = nodes.map{ |node| outputs.receive }
