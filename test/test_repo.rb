#!/usr/bin/env ruby

require 'vpim/repo'
require 'test/common'

class TestRepo < Test::Unit::TestCase
  Apple3 = Vpim::Repo::Apple3
  Directory = Vpim::Repo::Directory
  Uri = Vpim::Repo::Uri
  Agent = Vpim::Agent

  def setup
    @testdir = Dir.getwd + "/test" #File.dirname($0) doesn't work with rcov :-(
    @caldir = @testdir + "/calendars"
    @eventsz = Dir[@caldir + "/**/*.ics"].size
    assert(@testdir)
    assert(test(?d, @caldir), "no caldir "+@caldir)
  end

  def data_on_port(port, data)
    Thread.abort_on_exception = true
    thrd = Thread.new do
      require "webrick"
      server = WEBrick::HTTPServer.new( :Port => port )
      begin
        server.mount_proc("/") do |req,resp|
          resp.body = data
        end
        server.start
      ensure
        server.shutdown
      end
    end
    # Wait for server socket to come up
    while true
      begin
        s = TCPSocket.new("127.0.0.1", port)
      rescue Errno::ECONNREFUSED
        next
      end
      return thrd
    end
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

  def test_uri
    caldata = <<'__'
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
END:VEVENT
END:VCALENDAR
__
    server = data_on_port(9876, caldata)
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

end

