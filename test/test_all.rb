# -*- encoding : utf-8 -*-
#!/usr/bin/env ruby

require 'pp'

$-w = true

$:.unshift File.dirname(__FILE__) + "/../lib"
$:.unshift File.dirname(__FILE__) + "/.."


#pp [__LINE__, $:, $"]

require 'test/unit'

Dir[File.dirname(__FILE__) + "/test_*.rb"].each do |test|
  require test unless test =~ /test_all/
end

