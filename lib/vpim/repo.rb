=begin
  Copyright (C) 2008 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'vpim/icalendar'
require 'vpim/duration'

module Vpim
  # A Repo is a representation of an event repository. Currently iCalv3
  # repositories and directories containing .ics files are supported.
  #
  # TODO - should yield them if a block is given, or return
  # an enumerable otherwise. Later.
  module Repo
    def self.somethings_from_file(something, file) #:nodoc:
      somethings = []
      begin
        cals = Vpim::Icalendar.decode(File.open(file))

        cals.each do |cal|
          cal.send(something).each do |x|
            somethings << x
          end
        end
      end
      somethings
    end

    def self.events_from_file(file) #:nodoc:
      self.somethings_from_file("events", file)
    end

    def self.todos_from_file(file) #:nodoc:
      self.somethings_from_file("todos", file)
    end

    # An Apple iCal version 3 repository.
    module Ical3
      class Calendar
        def initialize(dir) # :nodoc:
          @dir = dir
        end
        def plist(key) #:nodoc:
           Plist::parse_xml( @dir + "/Info.plist")[key]
        end

        # The calendar name.
        def name
          plist "Title"
        end

        # Whether a calendar should be displayed.
        def displayed
          1 == plist("Checked")
        end

        # Array of all events defined in the calendar.
        def events #:yield: Vevent
          Dir[ @dir + "/Events/*.ics" ].map do |ics|
            Repo.events_from_file(ics)
          end.flatten
        end

        # Array of all todos defined in the calendar.
        def todos #:yield: Vevent
          Dir[ @dir + "/Events/*.ics" ].map do |ics|
            Repo.todos_from_file(ics)
          end.flatten
        end

      end

      def self.each(where = "~/Library/Calendars") # :yield: Apple::Calendar
        Dir[ File.expand_path(where + "/**/*.calendar") ].each do |dir|
          yield Calendar.new(dir)
        end
        self
      end
    end
    module Directory
      class Calendar
        def initialize(file) #:nodoc:
          @file = file
        end

        def name
          File.basename(@file)
        end

        def displayed
          true
        end

        def events
          Repo.events_from_file(@file)
        end

        def todos
          Repo.todos_from_file(@file)
        end
      end

      def self.each(where)
         Dir[ File.expand_path(where + "/**/*.ics") ].each do |file|
           yield Calendar.new(file)
         end
         self
      end
    end
  end
end

