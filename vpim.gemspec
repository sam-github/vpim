# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{vpim}
  s.version = "1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Sam Roberts"]
  s.date = %q{2011-05-20}
  s.description = %q{This is a pure-ruby library for decoding and encoding vCard and iCalendar data ("personal information") called vPim.}
  s.email = %q{vieuxtech@gmail.com}
  s.extra_rdoc_files = ["README", "CHANGES", "COPYING", "samples/README.mutt"]
  s.files = ["CHANGES", "COPYING", "ex_fmt_convert.rb", "ex_ics_api.rb", "Makefile", "mbox2vcard.rb", "outline.sh", "profile.rb", "profile.txt", "README", "setup.rb", "stamp.rb", "THANKS", "vpim.gemspec", "test/calendars", "test/calendars/weather.calendar", "test/calendars/weather.calendar/Events", "test/calendars/weather.calendar/Events/1205042405-0-0.ics", "test/calendars/weather.calendar/Events/1205128857-1-1205128857.ics", "test/calendars/weather.calendar/Events/1205215257-2--1884536782.ics", "test/calendars/weather.calendar/Events/1205301657-3--679062325.ics", "test/calendars/weather.calendar/Events/1205388057-4-526584932.ics", "test/calendars/weather.calendar/Events/1205474457-5-1732404989.ics", "test/calendars/weather.calendar/Events/1205560857-6--1356569450.ics", "test/calendars/weather.calendar/Events/1205647257-7--150403793.ics", "test/calendars/weather.calendar/Events/1205712057-8-1055761864.ics", "test/calendars/weather.calendar/Info.plist", "test/common.rb", "test/test_agent_atomize.rb", "test/test_agent_calendars.rb", "test/test_agent_ics.rb", "test/test_all.rb", "test/test_date.rb", "test/test_dur.rb", "test/test_field.rb", "test/test_ical.rb", "test/test_misc.rb", "test/test_repo.rb", "test/test_rrule.rb", "test/test_vcard.rb", "test/test_view.rb", "test/weekly.ics", "lib/vpim", "lib/vpim/address.rb", "lib/vpim/agent", "lib/vpim/agent/atomize.rb", "lib/vpim/agent/base.rb", "lib/vpim/agent/calendars.rb", "lib/vpim/agent/handler.rb", "lib/vpim/agent/ics.rb", "lib/vpim/attachment.rb", "lib/vpim/date.rb", "lib/vpim/dirinfo.rb", "lib/vpim/duration.rb", "lib/vpim/enumerator.rb", "lib/vpim/field.rb", "lib/vpim/icalendar.rb", "lib/vpim/maker", "lib/vpim/maker/vcard.rb", "lib/vpim/property", "lib/vpim/property/base.rb", "lib/vpim/property/common.rb", "lib/vpim/property/location.rb", "lib/vpim/property/priority.rb", "lib/vpim/property/recurrence.rb", "lib/vpim/property/resources.rb", "lib/vpim/repo.rb", "lib/vpim/rfc2425.rb", "lib/vpim/rrule.rb", "lib/vpim/time.rb", "lib/vpim/vcard.rb", "lib/vpim/version.rb", "lib/vpim/vevent.rb", "lib/vpim/view.rb", "lib/vpim/vjournal.rb", "lib/vpim/vpim.rb", "lib/vpim/vtodo.rb", "lib/vpim.rb", "samples/README.mutt"]
  s.homepage = %q{http://vpim.rubyforge.org}
  s.rdoc_options = ["--main", "README"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{vpim}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{iCalendar and vCard support for ruby}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
