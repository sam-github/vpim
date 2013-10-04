require './gemspec'

Gem::Specification.new do |s|
  info(s)
  s.name              = "vpim_icalendar"
  s.version           = "1.1"
  s.summary           = "Virtual gem depending on vPim's iCalendar support for ruby"
  s.description       = <<'---'
This is a virtual gem, it exists to depend on vPim, which provides iCalendar
support for ruby. You can install vPim directly.
---
  s.add_dependency("vpim")
end

