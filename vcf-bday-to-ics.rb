#!/usr/bin/ruby -w
# $Id: vcf-bday-to-ics.rb,v 1.1 2005/01/07 03:34:14 sam Exp $

$:.unshift File.dirname($0)

require 'getoptlong'
require 'vpim/vcard'
require 'pp'

HELP =<<EOF
Usage: vcf-bday-to-mutt.rb [input] [output]

Output defaults to stdout. Input defaults to stdin.

Options
  -h,--help      Print this helpful message.
EOF

opts = GetoptLong.new(
  [ "--help",    "-h",              GetoptLong::NO_ARGUMENT ]
)

$out = ARGV.last ? File.open(ARGV.pop) : $stdout
$in  = ARGV.last ? File.open(ARGV.pop) : $stdin

Vpim::Vcard.decode($in).each do |card|
  bday = card.field('BDAY') || next

  begin
    d = bday.to_date

    puts "#{card['fn']} -> bday #{d}"

  rescue Vpim::InvalidEncodingError
    puts "card for #{card['fn']} had invalid BDAY #{bday.value}, skipping!"
  rescue
    pp card
    raise
  end
end

