=begin
  Copyright (C) 2006 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

#:main:Vpim
#:title:vpim - a library to manipulate vCards and iCalendars
#
# Author::     Sam Roberts <sroberts@uniserve.com>
# Copyright::  Copyright (C) 2006 Sam Roberts
# License::    May be distributed under the same terms as Ruby
# Version::    0.16
# Homepage::   http://vpim.rubyforge.org
#
# vCard (RFC 2426) is a format for personal information, see Vpim::Vcard and
# Vpim::Maker::Vcard.
#
# iCalendar (RFC 2445) is a format for calendar related information, see
# Vpim::Icalendar.
#
# iCalendar was called vCalendar pre-IETF standaradization, and since both of
# these "v-formats" are commonly used personal information management, the
# library is called "vpim".
#
# vCard and iCalendar support is built on top of an implementation of the MIME
# Content-Type for Directory Information (RFC 2425). The basic RFC 2425 format
# is implemented by  Vpim::DirectoryInfo and Vpim::DirectoryInfo::Field.
#
# I am interested in having feedback on useability. In particular, if anybody
# using this library could send me any code showing how they call vPim, that
# would be very useful to me. It doesn't have to be complete, I would just like
# to see how the APIs are being called, to give me ideas for how to improve
# them.  Particularly, I'm interested in examples of encoding.
#
# = Project Information
#
# The latest release can be downloaded from the Ruby Forge project page:
#
# - http://rubyforge.org/projects/vpim
#
# If you are interested in notifications about new releases, or
# asking questions about vPim, please subscribe to "vpim-talk":
#
# - http://rubyforge.org/mailman/listinfo/vpim-talk
#
# = Examples
# 
# Sample utilities are provided as examples of using vPim in samples/.
# 
# vCard examples are:
# - link:ex_mkvcard.txt: an example of making a vCard
# - link:ex_cpvcard.txt: an example of copying and modifying a vCard
# - link:mutt-aliases-to-vcf.txt: convert a mutt aliases file to vCards
# - link:ex_get_vcard_photo.txt: pull photo data from a vCard
# - link:ab-query.txt: query the OS X Address Book to find vCards
# - link:vcf-to-mutt.txt: query vCards for matches, output in formats useful
#   with Mutt (see link:README.mutt for details)
# - link:vcard-dump.txt: dump all the fields in a vCard
# - link:tabbed-file-to-vcf.txt: convert a tab-delimited file to vCards, a
#   (small but) complete application contributed by Dane G. Avilla, thanks!
# - link:vcf-to-ics.txt: example of how to create calendars of birthdays from vcards
# 
# iCalendar examples are:
# - link:ics-to-rss.txt: prints todos as RSS, or starts a WEBrick servlet
#   that publishes todos as a RSS feed. Thanks to Dave Thomas for this idea,
#   from http://pragprog.com/pragdave/Tech/Blog/ToDos.rdoc.
# - link:cmd-itip.txt: prints emailed iCalendar invitations in human-readable
#   form, and see link:README.mutt for instruction on mutt integration. I get
#   a lot of meeting invitations from Lotus Notes/Domino users at work, and
#   this is pretty useful in figuring out where and when I am supposed to be.
# - link:reminder.txt: prints upcoming events and todos, by default from
#   Apple's iCal calendars
# - link:rrule.txt: utility for printing recurrence rules
# - link:ical-dump.txt: utility for dumping contents of .ics files
module Vpim
  VERSION = "0.16"

  # Return the API version as a string.
  def Vpim.version
    VERSION
  end
end

module Vpim
  # Exception used to indicate that data being decoded is invalid, the message
  # usually gives some clue as to exactly what is invalid.
  class InvalidEncodingError < StandardError; end
end

module Vpim::Methods
  module_function

  # Case-insensitive comparison of +str0+ to +str1+, returns true or false.
  # Either argument can be nil, where nil compares not equal to anything other
  # than nil.
  #
  # This is available both as a module function:
  #   Vpim::Methods.casecmp?("yes", "YES")
  # and an instance method:
  #   include Vpim::Methods
  #   casecmp?("yes", "YES")
  #
  # Will work with ruby1.6 and ruby 1.8.
  #
  # TODO - could make this be more efficient, but I'm supporting 1.6, not
  # optimizing for it.
  def casecmp?(str0, str1)
    if str0 == nil
      if str1 == nil
      return true
      else
        return fasle
      end
    end

    begin
      str0.casecmp(str1) == 0
    rescue NoMethodError
      str0.downcase == str1.downcase
    end
  end

end

