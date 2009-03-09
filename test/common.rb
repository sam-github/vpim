require 'test/unit'
require 'pp'

begin
  require 'rubygems'
rescue LoadError
end

module Enumerable
  unless self.methods.include? :count
    def count
      self.inject(0){|i,_| i + 1}
    end
  end
end

class Test::Unit::TestCase
  def data_on_port(data, port)
    Thread.abort_on_exception = true
    thrd = Thread.new do
      require "webrick"
      l =  WEBrick::Log.new(STDOUT, WEBrick::BasicLog::WARN)
      server = WEBrick::HTTPServer.new(
        :Port => port,
        :Logger => l #,
        #:AccessLog => l  # TODO - disable the access log, somehow
      )
      #server.logger.level = WEBrick::BasicLog::WARN
      #pp server.logger
      begin
        server.mount_proc("/") do |req,resp|
          resp.body = data.to_str
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
        s.close()
      rescue Errno::ECONNREFUSED
        next
      end
      return thrd
    end
  end
end

