#!/usr/bin/env nix-shell
#!nix-shell -p ruby -i ruby

require "json"

log = `journalctl -S -4h -g 'panicked at' -o json`
loglines = log.each_line.map do |line|
  next unless j = (JSON.parse(line) rescue nil)
  cursor = j["__CURSOR"]
  `journalctl --cursor="#{cursor}" -n 50`
end

puts JSON.pretty_unparse(loglines)
