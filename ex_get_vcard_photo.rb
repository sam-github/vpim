#!/usr/bin/ruby -w

require 'vpim/vcard'

d = File.new(ARGV[0]).read

v = Vpim::Vcard.decode(d).first

f = v.field('photo')

$stdout.write(f.value)

