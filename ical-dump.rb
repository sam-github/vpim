#!/usr/bin/ruby -w
#
# Calendars are in ~/Library/Calendars/

$:.unshift File.dirname($0)

require 'getoptlong'
require 'pp'

require 'vpim/icalendar'
require 'vpim/duration'

include Vpim

HELP =<<EOF
Usage: #{$0} <vcard>...

Options
  -h,--help         Print this helpful message.
  -n,--node         Dump as nodes.
  -d,--debug        Print debug information.

Examples:
EOF

opt_debug = nil
opt_node  = false

opts = GetoptLong.new(
  [ "--help",    "-h",   GetoptLong::NO_ARGUMENT ],
  [ "--node",    "-n",   GetoptLong::NO_ARGUMENT ],
  [ "--debug",   "-d",   GetoptLong::NO_ARGUMENT ]
)

opts.each do |opt, arg|
  case opt
    when "--help" then
      puts HELP
      exit 0

    when "--node" then
      opt_node = true

    when "--debug" then
      opt_debug = true
  end
end

if ARGV.length < 1
  puts "no input files specified, try -h!\n"
  exit 1
end

if opt_node

  ARGV.each do |file|
    tree = Vpim.expand(Vpim.decode(File.open(file).read(nil)))
    pp tree
  end

  exit 0
end

ARGV.each do |file|
  cals = Vpim::Icalendar.decode(File.open(file))

  cals.each do |cal|
    puts "vCalendar: version=#{cal.version/10.0} producer='#{cal.producer}'"

    if cal.protocol; puts "  protocol-method=#{cal.protocol}"; end

    events = cal.events
    events.each do |e|
      puts " vEvent:"
      if e.summary;      puts "   summary=#{e.summary}"; end
      if e.description;  puts "   description=<#{e.description}>"; end
      if e.comment;      puts "   comment=#{e.comment}"; end

      if e.organizer;    puts "   organizer=#{e.organizer.to_s}"; end

      e.attendees.each_with_index do |a,i|
        puts "   attendee[#{i}]=#{a.to_s}"
        puts "     role=#{a.role.upcase} participation-status=#{a.partstat.upcase} rsvp?=#{a.rsvp ? 'yes' : 'no'}"
      end

      if e.location;     puts "   location=#{e.location}"; end
      if e.status;       puts "   status=#{e.status}"; end
                         puts "   uid=#{e.uid}"
                         puts "   dtstamp=#{e.dtstamp.to_s}"
                         puts "   dtstart=#{e.dtstart.to_s}"
      if e.dtend;        puts "     dtend=#{e.dtend.to_s}"; end
      if e.duration;     puts "   duration=#{Duration.secs(e.duration).to_s}"; end
      # TODO - spec as hours/mins/secs
      if e.rrule;        puts "   rrule=#{e.rrule}"; end

      e.occurences.each_with_index do |t, i|
        if(i < 10)
          puts "   #{i+1} -> #{t}"
        else
          puts "   ..."
          break;
        end
      end
    end

    todos = cal.todos
    todos.each do |e|
      s = e.status ? " (#{e.status})" : ''
      puts "Todo#{s}: #{e.summary}"
    end

    if opt_debug
      pp cals
    end
  end
end

