#!/usr/bin/env ruby

require 'vpim/repo'
require 'vpim/agent/calendars'
require 'test/unit'

require 'pp'

module Enumerable
  def count
    self.inject(0){|i,_| i + 1}
  end
end

class TestRepo < Test::Unit::TestCase
  Apple3 = Vpim::Repo::Apple3
  Directory = Vpim::Repo::Directory
  Agent = Vpim::Agent
  Path = Agent::Path

  def setup
    @testdir = Dir.getwd + "/test" #File.dirname($0) doesn't work with rcov :-(
    @caldir = @testdir + "/calendars"
    @eventsz = Dir[@caldir + "/**/*.ics"].size
    assert(@testdir)
    assert(test(?d, @caldir), "no caldir "+@caldir)
  end

  def _test_each(repo, eventsz)
    repo.each do |cal|
      assert_equal(eventsz, cal.events.count, cal.name)
      assert("", File.extname(cal.name))
      assert_equal(cal.displayed, true)
      cal.events do |c|
        assert_instance_of(Vpim::Icalendar::Vevent, c)
      end
      cal.events.each do |c|
        assert_instance_of(Vpim::Icalendar::Vevent, c)
      end
      assert_equal(0, cal.todos.count)
      assert(cal.encode)
    end
  end

  def test_apple3
    repo = Apple3.new(@caldir)

    assert_equal(1, repo.count)

    _test_each(repo, @eventsz)
  end

  def test_dir
    assert(test(?d, @caldir))

    repo = Directory.new(@caldir)

    assert_equal(@eventsz, repo.count)

    _test_each(repo, 1)
  end

  def assert_is_text_calendar(text)
    lines = text.split("\n")
    lines = lines.first, lines.last
    assert_equal("BEGIN:VCALENDAR", lines.first.upcase, lines)
    assert_equal("END:VCALENDAR", lines.last.upcase, lines)
  end

  def test_agent_calendars
    repo = Apple3.new(@caldir)
    rest = Agent::Calendars.new(repo)

    out1, form = rest.get(Path.new("http://host/here", "/here"))
    assert_equal("text/html", form)
    #puts(out1)

    out1, form = rest.get(Path.new("http://host/here/weather%2fLeavenworth", "/here"))
    assert_equal("text/html", form)
    #puts(out1)

    out2, form = rest.get(Path.new("http://host/here/weather%2fLeavenworth/calendar", "/here"))
    assert_equal("text/calendar", form)
    assert_is_text_calendar(out2)

    #assert_equal(out1, out2)

    assert_raise(Vpim::Agent::NotFound) do
      rest.get(Path.new("http://host/here/weather%2fLeavenworth/atom", "/here"))
    end
    assert_raise(Vpim::Agent::NotFound) do
      rest.get(Path.new("http://host/here/no_such_calendar", "/here"))
    end

    assert_equal(["","/","/"], Vpim::Agent::Path.split_path("/%2F/%2F"))
    assert_equal(["/","/"], Vpim::Agent::Path.split_path("%2F/%2F"))
    assert_equal(["calendars", "weather/Leavenworth"],
                 Vpim::Agent::Path.split_path("calendars/weather%2FLeavenworth"))
  end

  def test_path
    p = Path.new("http://host.ex")
    assert_equal(nil, p.shift)
    assert_equal(nil, p.shift)

    p = Path.new("http://host.ex/")
    assert_equal(nil, p.shift)
    assert_equal(nil, p.shift)

    p = Path.new("http://host.ex/a")
    assert_equal("a", p.shift)
    assert_equal(nil, p.shift)

    p = Path.new("http://host.ex/a/b")
    assert_equal("a", p.shift)
    assert_equal("b", p.shift)
    assert_equal(nil, p.shift)

    p = Path.new("http://host.ex/a/b/")
    assert_equal("a", p.shift)
    assert_equal("b", p.shift)
    assert_equal(nil, p.shift)

    p = Path.new("http://host.ex/a/b/c")
    assert_equal("a", p.shift)
    assert_equal("b", p.shift)
    assert_equal("c", p.shift)
    assert_equal(nil, p.shift)
  end

end

