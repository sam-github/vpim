require 'test/common'
require 'sinatra/test'
require 'vpim/agent/ics'

class TestIcsAgent < Test::Unit::TestCase
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

  def _test_ics_atom_query(scheme)
    @caldata = open("test/weekly.ics").read

    get "/atom?#{scheme}://127.0.0.1:9876"

    assert_match(/<\?xml/, @response.body)
    assert_equal(Vpim::Agent::Atomize::MIME, @response["Content-Type"])
    assert_equal(200, @response.status)
    assert_match(Regexp.new( Regexp.quote(
        "<id>http://example.org/atom?#{scheme}://127.0.0.1:9876</id>"
    )), @response.body)
  end

  def test_ics_atom_query_http
    _test_ics_atom_query "http"
  end

  def test_ics_atom_query_webcal
    _test_ics_atom_query "webcal"
  end

  def test_ics
    get ""

    assert_match(/<html/, @response.body)
    assert_equal("text/html", @response["Content-Type"])
    assert_equal(200, @response.status)
    assert_match(Regexp.new(Regexp.quote("<title>Subscribe")), @response.body)
  end

  def test_ics_query
    @caldata = open("test/calendars/weather.calendar/Events/1205042405-0-0.ics").read

    get "?http://127.0.0.1:9876"

    assert_match(/<html/, @response.body)
    assert_equal("text/html", @response["Content-Type"])
    assert_equal(200, @response.status)

    assert_match(Regexp.new(Regexp.quote("Subscribe to")), @response.body)
  end

  def test_ics_post
    post "/", :url => "http://example.com"
    assert_equal(302, @response.status)
    assert_equal("http://example.org?http://example.com", @response.headers["Location"])
  end

  def test_ics_atom
    get "/atom"
    assert_equal(302, @response.status)
    assert_equal("http://example.org", @response.headers["Location"])
  end

  def test_ics_style
    get "/style.css"
    assert_match(/body \{/, @response.body)
    assert_equal("text/css", @response["Content-Type"])
    assert_equal(200, @response.status)
  end

  def test_ics_query_bad
    get "/?url://example.com"
    assert_equal(200, @response.status)
    assert_match(/Sorry/, @response.body)
  end

  def test_ics_atom_query_bad
    #Vpim::Agent::Ics.enable :raise_errors

    get "/atom?url://example.com"
    assert_equal(302, @response.status)
    assert_equal("http://example.org?url://example.com", @response.headers["Location"])
  end

end

