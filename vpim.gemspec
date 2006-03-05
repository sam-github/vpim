require 'rubygems'

Gem.manage_gems

spec = Gem::Specification.new do |s|
  s.name              = "vpim"
  s.version           = "0.17"
  s.author            = "Sam Roberts"
  s.email             = "sroberts@uniserve.com"
  s.homepage          = "http://vpim.rubyforge.org"
  s.platform          = Gem::Platform::RUBY
  s.summary           = "a library to manipulate vCards and iCalendars"
  s.files             = Dir.glob("{lib}/**/*").delete_if {|item| item.include?(".svn")}
  s.require_path      = "lib"
	s.has_rdoc          = true
	s.autorequire       = "vpim"
end

if $0==__FILE__
  Gem::Builder.new(spec).build
end
