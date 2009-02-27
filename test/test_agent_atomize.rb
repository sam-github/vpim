require 'test/common'

require 'vpim/agent/atomize'
require 'vpim/icalendar'

class TextAgentAtomize < Test::Unit::TestCase

  def atomize(cal, feeduri, caluri)
    ical = Vpim::Icalendar.decode(cal).first
    feed = Vpim::Agent::Atomize.calendar(ical, feeduri, caluri)
    return ical, feed
  end

  def test_minimal
    ical, feed = atomize(<<'__', "http://example.com/feed", "http://example.com/calendar")
BEGIN:VCALENDAR
BEGIN:VEVENT
DTSTART:20090214T144503
END:VEVENT
END:VCALENDAR
__

  assert_equal(feed.entries.size, 1)
  assert_equal("http://example.com/feed", feed.id)
  assert_equal("http://example.com/calendar - atomized!", feed.title)
  assert(feed.to_xml.to_str)
  assert_equal(nil, feed.entries.first.title)
  assert_equal(nil, feed.entries.first.content)
  #puts feed.to_xml
  end

  def test_small
    ical, feed = atomize(<<'__', "http://example.com/feed", "http://example.com/calendar")
BEGIN:VCALENDAR
BEGIN:VEVENT
DTSTART:20090214T144503
SUMMARY:I am summarized
DESCRIPTION:And I am described
UID:very, very, unique
END:VEVENT
END:VCALENDAR
__

  assert_equal(feed.entries.size, 1)
  assert_equal("http://example.com/feed", feed.id)
  assert_equal("http://example.com/calendar - atomized!", feed.title)
  assert_equal("I am summarized", feed.entries.first.title)
  assert_equal("And I am described", feed.entries.first.content)
  assert(feed.to_xml.to_str)
  #puts feed.to_xml
  end

end


