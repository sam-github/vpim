require 'rubygems'
require 'pp'
require 'rake'
require_relative 'gemspec'
require_relative 'lib/vpim/version'

Gem::Specification.new do |s|
  info(s)
  s.name              = "vpim"
  s.version           = Vpim::VERSION
  s.summary           = "iCalendar and vCard support for ruby"
  s.description       = <<'---'
This is a pure-ruby library for decoding and encoding vCard and iCalendar data
("personal information") called vPim.
---
  s.extra_rdoc_files  = ["README.rdoc", "CHANGES", "COPYING", "samples/README.mutt" ]

  candidates = FileList[
    'lib/vpim/**/*.rb',
    'lib/vpim.rb',
    'bin/*',
    'samples/*',
    'test/test_*.rb',
    'COPYING',
    'README.rdoc',
    'CHANGES',
  ].to_a

  s.files             = candidates
  s.test_files        = Dir.glob("test/test_*.rb")
  s.executables       = FileList["bin/*"].map{|path| File.basename(path)}

  s.require_path      = "lib"
# s.add_dependency("plist")
# s.autorequire       = "vpim"
end

