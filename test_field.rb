#!/usr/bin/ruby -w

$:.unshift File.dirname($0)

require 'test/unit'
require 'pp'
require 'vpim/field'

Field=Vpim::DirectoryInfo::Field

class TestField < Test::Unit::TestCase

  def test_field0
    assert_equal('name:', line = Field.encode0(nil, 'name'))
    assert_equal([ nil, 'name', {}, ''], Field.decode0(line))

    assert_equal('name:value', line = Field.encode0(nil, 'name', {}, 'value'))
    assert_equal([ nil, 'name', {}, 'value'], Field.decode0(line))

    assert_equal('name;encoding=b:dmFsdWU=', line = Field.encode0(nil, 'name', { 'encoding'=>:b64 }, 'value'))
    assert_equal([ nil, 'name', { 'encoding'=>['b']}, ['value'].pack('m').chomp ], Field.decode0(line))

    assert_equal('group.name:value', line = Field.encode0('group', 'name', {}, 'value'))
    assert_equal([ 'group', 'name', {}, 'value'], Field.decode0(line))
  end

  def tEst_invalid_fields
    [
      'g.:',
      ':v',
    ].each do |line|
      assert_raises(Vpim::InvalidEncodingError) { Field.decode0(line) }
    end
  end

  def test_field_modify
    f = Field.create('name')

    assert_equal('', f.value)
    f.value = ''
    assert_equal('', f.value)
    f.value = 'z'
    assert_equal('z', f.value)

    f.group = 'z.b'
    assert_equal('z.b', f.group)
    assert_equal("z.b.name:z\n", f.encode)

    assert_raises(TypeError) { f.value = :group }

    assert_equal('z.b', f.group)

    assert_equal("z.b.name:z\n", f.encode)

    assert_raises(TypeError) { f.group = :group }

    assert_equal("z.b.name:z\n", f.encode)
    assert_equal('z.b', f.group)

    f['p0'] = "hi julie"

    assert_equal("z.b.name;p0=hi julie:z\n", f.encode)
    assert_equal(['hi julie'], f.param('p0'))
    assert_equal(['hi julie'], f['p0'])
    assert_equal('name', f.name)
    assert_equal('z.b', f.group)

    # FAIL   assert_raises(ArgumentError) { f.group = 'z.b:' }

    assert_equal('z.b', f.group)

    f.value = 'some text'
    
    assert_equal('some text', f.value)
    assert_equal('some text', f.value_raw)

    f['encoding'] = :b64

    assert_equal('some text', f.value)
    assert_equal([ 'some text' ].pack('m*').chomp, f.value_raw)
  end

  def test_field_wrapping
    assert_equal("0:x\n",             Vpim::DirectoryInfo::Field.create('0', 'x' * 1).encode(4))
    assert_equal("0:xx\n",            Vpim::DirectoryInfo::Field.create('0', 'x' * 2).encode(4))
    assert_equal("0:xx\n x\n",        Vpim::DirectoryInfo::Field.create('0', 'x' * 3).encode(4))
    assert_equal("0:xx\n xx\n",       Vpim::DirectoryInfo::Field.create('0', 'x' * 4).encode(4))
    assert_equal("0:xx\n xxxx\n",     Vpim::DirectoryInfo::Field.create('0', 'x' * 6).encode(4))
    assert_equal("0:xx\n xxxx\n x\n", Vpim::DirectoryInfo::Field.create('0', 'x' * 7).encode(4))
  end
end

