require 'test/common'
require 'sinatra/test/unit'

require 'vpim/agent/app'

class IcsAgent < Test::Unit::TestCase

  def to_str
    @caldata
  end

  def setup
    @thrd = data_on_port(self, 9876)
  end
  def teardown
    @thrd.kill
  end

  def test_ics_atom_query
    @caldata = open('test/calendars/weather.calendar/Events/1205042405-0-0.ics').read

    get '/ics/atom?http://127.0.0.1:9876'

    #pp @response
    assert(@response.body =~ /<\?xml/)
    assert_equal(Vpim::Agent::Atomize::MIME, @response['Content-Type'])
    assert_equal(200, @response.status)
    assert(@response.body =~ Regexp.new(
      Regexp.quote(
        "<id>http://example.org/ics/atom?http://127.0.0.1:9876</id>"
    )), @response.body)
  end

  def test_ics
    get '/ics'

    assert(@response.body =~ /<html/)
    assert_equal('text/html', @response['Content-Type'])
    assert_equal(200, @response.status)
    assert(@response.body =~ Regexp.new(
      Regexp.quote("<title>Subscribe")), @response.body)
  end

  def test_ics_query
    @caldata = open('test/calendars/weather.calendar/Events/1205042405-0-0.ics').read

    get '/ics?http://127.0.0.1:9876'

    assert(@response.body =~ /<html/)
    assert_equal('text/html', @response['Content-Type'])
    assert_equal(200, @response.status)

    assert(@response.body =~ Regexp.new(
      Regexp.quote("Subscribe to")), @response.body)
  end

  def test_ics_atom
    get '/ics/atom'
    assert_equal(302, @response.status)
  end

=begin

WTF? Sinatra doesn't run it's error catcher in unit test mode?
  def test_ics_atom_query_bad
    get '/ics/atom?http://example.com'
    assert_equal(500, @response.status)
    assert(@response.body =~ Regexp.new(
      Regexp.quote("error")), @response.body)
  end
=end

end

