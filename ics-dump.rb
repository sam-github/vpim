#!/usr/bin/env ruby
#
# Calendars are in ~/Library/Calendars/

$:.unshift File.dirname($0) + "/lib"

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

def puts_common(e)
  [
    :access_class,
    :created,
    :description,
    :dtstamp,
    :dtstart,
    :status,
    :summary,
    :uid,
    :url,
    :organizer,
  ].each do |m|
    v = e.send(m)
    if v
      puts "  #{m}=<#{v.to_s}>"
    end
  end

  [
    :categories,
    :comments,
    :contacts
  ].each do |m|
    e.send(m).each_with_index do |v,i|
      puts "  #{m}[#{i}]=<#{v.to_s}>"
    end
  end

  e.attendees.each_with_index do |a,i|
    puts "  attendee[#{i}]=#{a.to_s}"
      puts "   role=#{a.role.upcase} participation-status=#{a.partstat.upcase} rsvp?=#{a.rsvp ? 'yes' : 'no'}"
  end
end

ARGV.each do |file|
  cals = Vpim::Icalendar.decode(File.open(file))

  cals.each_with_index do |cal, i|
    if i > 0
      puts
    end

    puts "vCalendar[#{i}]:"
    puts " version=#{cal.version/10.0}"
    puts " producer=#{cal.producer}"

    if cal.protocol; puts " protocol=#{cal.protocol}"; end

    events = cal.events

    events.each_with_index do |e, i|
      puts " vEvent[#{i}]:"

      puts_common(e)

#     if e.comment;      puts "  comment=#{e.comment}"; end


      if e.location;     puts "   location=#{e.location}"; end
      if e.geo;          puts "   geo=#{e.geo.inspect}"; end
      if e.dtend;        puts "     dtend=#{e.dtend.to_s}"; end
      if e.duration;     puts "   duration=#{Duration.secs(e.duration).to_s}"; end

      puts "  priority=#{e.priority}"
      puts "  transparency=#{e.transparency}"

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

    todos.each_with_index do |e,i|
      puts " vTodo[#{i}]:"

      puts_common(e)

      puts "  priority=#{e.priority}"

      if e.geo;          puts "   geo=#{e.geo.inspect}"; end
    end

    journals = cal.journals

    journals.each_with_index do |e,i|
      puts " vJournal[#{i}]:"

      puts_common(e)
    end

    if opt_debug
      pp cals
    end
  end
end

