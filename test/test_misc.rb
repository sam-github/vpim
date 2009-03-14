#!/usr/bin/env ruby

require 'test/unit'
require 'vpim/version'

class TestVpimMisc < Test::Unit::TestCase

  def test_version
    assert_match(/0.\d+/, Vpim.version)
  end

end

