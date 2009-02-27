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

  def test_ics_rss
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

end

