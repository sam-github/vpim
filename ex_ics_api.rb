require 'vpim/icalendar'

cal = Vpim::Icalendar.create2

cal.add_event do |e|
  e.dtstart       Date.new(2005, 04, 28)
  e.dtend         Date.new(2005, 04, 29)
  e.summary       "Monthly meet-the-CEO day"
  e.description <<'---'
Unlike last one, this meeting will change your life because
we are going to discuss your likely demotion if your work isn't
done soon.
---
  e.categories    [ 'APPOINTMENT' ]
  e.categories do |c| c.push 'EDUCATION' end
  e.url           'http://www.example.com'
  e.sequence      0
  e.access_class  "PRIVATE"
  e.transparency  'OPAQUE'
  e.set_text('LOCATION', 'my location')

  now = Time.now
  e.created       now
  e.lastmod       now


  e.organizer do |o|
    o.cn = "Example Organizer, Mr."
    o.uri = "mailto:organizer@example.com"
  end

  attendee = Vpim::Icalendar::Address.create("mailto:attendee@example.com")
  attendee.rsvp = true
  e.add_attendee attendee
end

icsfile = cal.encode

puts '--- Encode:'

puts icsfile

puts '--- Decode:'

cal = Vpim::Icalendar.decode(icsfile).first

cal.components do |e|
  puts e.summary
  puts e.description
  puts e.dtstart.to_s
  puts e.dtend.to_s
end


