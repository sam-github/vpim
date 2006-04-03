require 'svn'
require 'rubygems'

Gem.manage_gems

spec = Gem::Specification.new do |s|
  s.name              = "vpim"
  s.version           = "0.#{Svn.info['Revision']}"
  s.author            = "Sam Roberts"
  s.email             = "sroberts@uniserve.com"
  s.homepage          = "http://vpim.rubyforge.org"
  s.rubyforge_project = "vpim"
  s.summary           = "iCalendar and vCard support for ruby"
  s.description       = <<'---'
This is a pure-ruby library for decoding and encoding vCard and iCalendar data
("personal information") called vPim.
---
  s.platform          = Gem::Platform::RUBY
  s.has_rdoc          = true
  s.files             = Dir.glob("lib/**/*.rb").delete_if { |i| i.include? 'agent' }
  s.require_path      = "lib"
  s.autorequire       = "vpim"
end

if $0==__FILE__
  Gem::Builder.new(spec).build
end
