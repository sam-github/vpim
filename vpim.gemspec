require 'ubygems'
require 'pp'
require 'rake'
require 'svn'

Gem.manage_gems

spec = Gem::Specification.new do |s|
  s.name              = "vpim"
  s.version           = "0.#{Svn.info['Revision']}"
  s.author            = "Sam Roberts"
  s.email             = "viextech+vpimgem@rubyforge.org"
  s.homepage          = "http://vpim.rubyforge.org"
  s.rubyforge_project = "vpim"
  s.summary           = "iCalendar and vCard support for ruby"
  s.description       = <<'---'
This is a pure-ruby library for decoding and encoding vCard and iCalendar data
("personal information") called vPim.
---
  s.has_rdoc          = true
  s.extra_rdoc_files  = ["README", "CHANGES", "COPYING", "samples/README.mutt" ]

  candidates = FileList[
    'lib/**/*.rb',
    'bin/*',
    'samples/*',
    'test/test_*.rb',
    'COPYING',
    'README',
    'CHANGES',
  ].to_a

  candidates.reject!{|path| path.include? 'agent'}

  s.files             = candidates
  s.test_files        = Dir.glob("test/test_*.rb")
  s.executables       = FileList["bin/*"].map{|path| File.basename(path)}

  pp [s.files, s.test_files, s.executables]

  s.require_path      = "lib"
  s.add_dependency("plist")
# s.autorequire       = "vpim"
end

#require 'hoe'
#
#Hoe.new(spec.name, spec.version) do |p|
#  p.rubyforge_name = "vpim"
#  p.remote_rdoc_dir = '' # Release to root
#end
#

if $0==__FILE__
  Gem::Builder.new(spec).build
# Gem::Builder.new(specvcard).build
# Gem::Builder.new(specicalendar).build
end

