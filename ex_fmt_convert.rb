require 'vpim/icalendar'
require 'open-uri'

class Convert
  def initialize(io)
    @io = io
  end

  def each
    @io.each do |line|
      line.gsub!("\r", "\\n")
      yield line
    end
  end
end

io = open("http://upcoming.org/calendar/metro/45")
cvt = Convert.new(io)
cal = Vpim::Icalendar.decode(cvt).first

cal.components do |c|
  puts "-------------------------------------------------"
  puts c.description
end

