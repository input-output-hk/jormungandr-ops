#!/usr/bin/env crystal

require "json"

def nixops(args : Array(String))
  pretty = (["nixops"] + args.map { |arg|
    case arg
    when Array(String)
      "'#{arg.join(" ")}'"
    else
      arg
    end
  }).join(" ")

  puts pretty

  if system("nixops", args)
    puts "ok."
  else
    STDERR.puts "failed with #{$?.exit_status}"
  end
end

def deploy(args)
  nixops(["deploy"] + args)
end

def nix_eval(something)
  Array(String).from_json(
    `nix eval --json '((import ./scripts/nodes.nix).#{something}Names)'`
  )
end

def resources
  nix_eval("initalResources")
end

def nixops_info
  lines = `nixops info --no-eval`.each_line.map do |line|
    line.split("|").map { |col| col.strip }
  end

  i = lines.index([""]) || 0

  lines.to_a[(i + 4)..-2].map { |line|
    {
      name:   line[1],
      status: line[2],
      type:   line[3],
      id:     line[4],
      ip:     line[5],
    }
  }
end

machines = {
  relays: nix_eval("relays"),
  stakes: nix_eval("stakes"),
}

# puts "initial check..."
# machines.each do |key, all_names|
#   (all_names).each_slice(500) do |names|
#     nixops(["check", "--include"] + names)
#   end
# end

to_deploy = [] of String
to_stop = [] of String

info = nixops_info
info.each do |i|
  next unless i[:type].split.first == "ec2"
  status = i[:status].split("/").first.strip
  name = i[:name]

  case status
  when "Missing"
    to_deploy << name
  when "Stopped"
  when "Unreachable"
  when "Up"
    to_stop << name if machines[:stakes].includes?(name)
  end
end

if to_stop.any?
  puts "stopping #{to_stop.join(' ')}"
  nixops(
    ["ssh-for-each", "-p", "--include"] +
    to_stop +
    ["--", "
     if [[ -d /var/lib/jormungandr ]]; then
       systemctl stop jormungandr;
       rm -rf /var/lib/jormungandr;
       systemctl poweroff;
     fi
    "]
  )
  exit
end

puts "total #{machines[:relays].size} relays"
puts "      #{machines[:stakes].size} stakes"
puts "      #{resources.size} resources"
puts "deploying monitoring and initial resources..."

# deploy ["--kill-obsolete", "--include", "monitoring", "monitoring-ip"] + resources

puts "now deploying #{to_deploy.size} machines..."

from_here = false

machines.each do |key, all_names|
  all_names.each_slice(25) do |names|
    if names.includes?("stake-c-225")
      from_here = true
    end

    next unless from_here

    ips = names.map { |name| "#{name}-ip" }
    args = ["--include"] + (names + ips).sort
    deploy args
  end
end

puts "Nothing left to do"
