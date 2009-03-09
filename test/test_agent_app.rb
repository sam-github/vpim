require 'test/common'
require 'sinatra/test'

require 'vpim/agent/ics'

class IcsAgent < Test::Unit::TestCase
  include Sinatra::Test

  def to_str
    @caldata
  end

  def setup
    @thrd = data_on_port(self, 9876)
    @app = Vpim::Agent::Ics
  end
  def teardown
    @thrd.kill
  end

  def test_ics_atom_query
    @caldata = open('test/calendars/weather.calendar/Events/1205042405-0-0.ics').read

    get '/atom?http://127.0.0.1:9876'

    #pp @response
    assert(@response.body =~ /<\?xml/)
    assert_equal(Vpim::Agent::Atomize::MIME, @response['Content-Type'])
    assert_equal(200, @response.status)
    assert(@response.body =~ Regexp.new(
      Regexp.quote(
        "<id>http://example.org/atom?http://127.0.0.1:9876</id>"
    )), @response.body)
  end

  def test_ics
    get ''

    assert(@response.body =~ /<html/)
    assert_equal('text/html', @response['Content-Type'])
    assert_equal(200, @response.status)
    assert(@response.body =~ Regexp.new(
      Regexp.quote("<title>Subscribe")), @response.body)
  end

  def test_ics_query
    @caldata = open('test/calendars/weather.calendar/Events/1205042405-0-0.ics').read

    get '?http://127.0.0.1:9876'

    assert(@response.body =~ /<html/)
    assert_equal('text/html', @response['Content-Type'])
    assert_equal(200, @response.status)

    assert(@response.body =~ Regexp.new(
      Regexp.quote("Subscribe to")), @response.body)
  end

  def test_ics_atom
    get '/atom'
    assert_equal(302, @response.status)
  end

=begin

WTF? Sinatra doesn't run it's error catcher in unit test mode?
  def test_ics_atom_query_bad
    Vpim::Aent::Ics.disable :raise_errors

    get '/atom?http://example.com'
    assert_equal(500, @response.status)
    assert(@response.body =~ Regexp.new(
      Regexp.quote("error")), @response.body)
  end
=end

end

