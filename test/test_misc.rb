# -*- encoding : utf-8 -*-
#!/usr/bin/env ruby

require 'test/unit'
require 'vpim/version'

class TestVpimMisc < Test::Unit::TestCase

  def test_version
    assert_match(/\d+.\d+.\d+/, Vpim.version)
  end

end
