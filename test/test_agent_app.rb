
begin
  require 'rubygems'
rescue LoadError
end

require 'sinatra/test/unit'
require 'test/common'

require 'vpim/agent/app'

class IcsAgent < Test::Unit::TestCase

  def test_ics_rss
    caldata = open('test/calendars/weather.calendar/Events/1205042405-0-0.ics').read
    thrd = data_on_port(caldata, 9876)
    begin
      get '/ics/rss?http://127.0.0.1:9876'
    ensure
      thrd.kill
    end
    assert(@response.body =~ /<\?xml/)
    assert_equal(@response['Content-Type'], Vpim::Agent::Atomize::MIME)
  end

end

