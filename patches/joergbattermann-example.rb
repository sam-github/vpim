<% require 'vpim/icalendar'

cal = Vpim::Icalendar.create2

cal.add_event do |e|
  e.dtstart  @event.starttime
  e.dtend @event.endtime != nil ? @event.endtime : @event.starttime + 15.minutes
  e.summary @event.title
  e.description !@event.description.blank? ? @event.description : ""
  e.categories    [ 'PROJECTS' ]
  e.url  !@event.url.blank? ? @event.url : ""
  e.sequence      0
  e.access_class  "PRIVATE"
  e.transparency  'OPAQUE'

  e.created @event.created_at
  e.lastmod @event.updated_at

  e.organizer do |o|
    o.cn = @user.full_name
    o.uri = "mailto:#{@user.email}"
  end

  attendee = Vpim::Icalendar::Address.create("mailto:#{@user.email}")
  attendee.rsvp = true
  e.add_attendee attendee
end

icsfile = cal.encode
%>
<%= icsfile %>


BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Ensemble Independent//vPim 0.619//EN
CALSCALE:Gregorian
BEGIN:VEVENT
DTSTART:20080505T183000
DTEND:20080505T223000
SUMMARY:test!?
DESCRIPTION:
CATEGORIES:PROJECTS
URL:http://blogwi.se
SEQUENCE:0
CLASS:PRIVATE
CREATED:20080505T163212
LAST-MODIFIED:20080505T163214
ORGANIZER;CN=Joerg Battermann:mailto:jb@joergbattermann.com
ATTENDEE;RSVP=true:mailto:jb@joergbattermann.com
END:VEVENT
END:VCALENDAR

