#!/usr/bin/env ruby

require 'vpim/repo'
require 'test/common'

class TestRepo < Test::Unit::TestCase
  Apple3 = Vpim::Repo::Apple3
  Directory = Vpim::Repo::Directory
  Uri = Vpim::Repo::Uri

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

  def test_uri_http
    caldata = open('test/calendars/weather.calendar/Events/1205042405-0-0.ics').read

    server = data_on_port(caldata, 9876)
    begin
      c = Uri::Calendar.new("http://localhost:9876")
      assert_equal(caldata, c.encode)

      repo = Uri.new("http://localhost:9876")

      assert_equal(1, repo.count)

      _test_each(repo, 1)
    ensure
      server.kill
    end
  end

  def test_uri_webcal
    caldata = open('test/calendars/weather.calendar/Events/1205042405-0-0.ics').read

    server = data_on_port(caldata, 9876)
    begin
      c = Uri::Calendar.new("webcal://localhost:9876")
      assert_equal(caldata, c.encode)

      repo = Uri.new("webcal://localhost:9876")

      assert_equal(1, repo.count)

      _test_each(repo, 1)
    ensure
      server.kill
    end
  end


  def test_uri_invalid
    assert_raises(ArgumentError) do
      Uri.new("url")
    end
    assert_raises(ArgumentError) do
      c = Uri::Calendar.new("url://localhost")
    end
    assert_raises(ArgumentError) do
      c = Uri::Calendar.new("https://localhost")
    end
  end

  def test_uri_unreachable
    assert_raises(SocketError) do
      r = Uri.new("http://example.example")
      c = r.find{true}
      c.events{}
    end
    assert_raises(Errno::ECONNREFUSED) do
      r = Uri.new("http://rubyforge.org:81")
      c = r.find{true}
      c.events{}
    end
    assert_raises(StandardError, Vpim::InvalidEncodingError) do
      r = Uri.new("http://rubyforge.org/lua-rocks-my-world")
      c = r.find{true}
      c.events{}
    end
  end

  def test_uri_unparseable
    assert_raises(Vpim::InvalidEncodingError) do
      r = Uri.new("http://example.com:80")
      c = r.find{true}
      c.events{}
    end
  end

end

