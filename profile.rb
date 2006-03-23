require 'vpim/icalendar'

#x10000 = "This:That\n is more" * 1000

Vpim::Icalendar.decode(open("data/ics/profile.ics"))

