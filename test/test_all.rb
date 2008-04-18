#!/usr/bin/env ruby

$-w = true

$:.unshift File.dirname($0)

require 'pp'

pp [__LINE__, $:, $"]

require 'test/unit'

require 'test_date.rb'
require 'test_dur.rb'
require 'test_field.rb'
require 'test_ical.rb'
require 'test_rrule.rb'
require 'test_vcard.rb'

