#!/usr/bin/ruby -w

$:.unshift File.dirname($0)

require 'pp'
require 'getoptlong'
require 'vpim/vcard'

HELP =<<EOF
Usage: #{$0} <vcard>...

Options
  -h,--help      Print this helpful message.
  -d,--debug     Print debug information.

Examples:
EOF

opt_debug = nil

opts = GetoptLong.new(
  [ "--help",    "-h",              GetoptLong::NO_ARGUMENT ],
  [ "--debug",   "-d",              GetoptLong::NO_ARGUMENT ]
)

opts.each do |opt, arg|
  case opt
    when "--help" then
      puts HELP
      exit 0

    when "--debug" then
      opt_debug = true
  end
end

if ARGV.length < 1
  puts "no vcard files specified, try -h!\n"
  exit 1
end

ARGV.each do |file|

  cards = Vpim::Vcard.decode(File.open(file))

  cards.each do |card|
    card.each do |line|
      puts "..#{line.name.capitalize}=#{line.value_raw}"

      if line.group
        puts " group=#{line.group}"
      end

      line.each_param do |param, values|
        puts " #{param}=[#{values.join(", ")}]"
      end
    end

    if opt_debug
      card.groups.sort.each do |group|
        card.enum_by_group(group).each do |field|
          puts "#{group} -> #{field.inspect}"
        end
      end
    end

    puts ""
  end
end

