#!/usr/bin/ruby -w
# $Id: vcf-bday-to-ics.rb,v 1.1 2005/01/07 03:34:14 sam Exp $

$:.unshift File.dirname($0)

require 'getoptlong'

require 'vpim/vcard'
require 'vpim/icalendar'

require 'pp'

$stderr.sync = true
$stdout.sync = true


HELP =<<EOF
Usage: vcf-to-ics.rb [input] [output]

Converts all birthdays in the vCard(s) as repeating events in an iCalendar.

Output defaults to stdout. Input defaults to stdin.

Options
  -h,--help      Print this helpful message.
EOF

opts = GetoptLong.new(
  [ "--help",    "-h",              GetoptLong::NO_ARGUMENT ]
)

$out = ARGV.last ? File.open(ARGV.pop) : $stdout
$in  = ARGV.last ? File.open(ARGV.pop) : $stdin

cal = Vpim::Icalendar.create #( 'X-WR-CALNAME' => "Birthdays" )


Vpim::Vcard.decode($in).each do |card|
  begin
    bday = card.field('BDAY') || next
    date = nil

    begin
      date = bday.to_date

    rescue Vpim::InvalidEncodingError
      STDERR.puts "card for #{card['fn']} had invalid BDAY #{bday.value}"

      if bday.value =~ /(\d+)-(\d+)-(\d+)/
        y = $1.to_i
        m = $2.to_i
        d = $3.to_i
        if(y < 1900)
          y = Time.now.year
        end
        date = Date.new(y, m, d)
      end
    end

    if date
      STDERR.puts "#{card['fn']} -> bday #{date} (#{date.inspect})"

      cal.push Vpim::Icalendar::Vevent.create(
        date,
        'SUMMARY' => "Birthday for #{card['fn']}",
        'RRULE' => 'FREQ=YEARLY'
        )
    end

  rescue
    pp card
    raise
  end
end

puts cal.to_s

