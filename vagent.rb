#!/usr/bin/ruby

$-w = true

base = ARGV.first

$:.unshift base+"/Contents/Resources/lib"

STDOUT.sync = STDERR.sync = true

puts "agent base: #{base}"
puts "require path: #{$:.inspect}"

p Dir.getwd

require "vpim/agent/main"

