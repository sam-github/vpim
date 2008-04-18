=begin
  Copyright (C) 2006 Sam Roberts
  Copyright (C) 2008 Robert Berger

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'vpim'

module Vpim
  
  # Override of class Rrule to make the by method accessible
  class Rrule
    attr_reader :by
  end
  
  class Icalendar
    
    # Overrides of the standard Vpim::Icalendar class
    
    
    # Create a new Icalendar object from +fields+, an array of
    # DirectoryInfo::Field objects.
    #
    # When decoding Calendar data, you would usually use Icalendar.decode(),
    # which decodes the data into the field arrays, and calls this method
    # for each Calendar it finds.
    # Added VTIMEZONE factory R. Berger
    def initialize(fields) #:nodoc:
      # seperate into the outer-level fields, and the arrays of component
      # fields
      outer, inner = Vpim.outer_inner(fields)

      # Make a dirinfo out of outer, and check its an iCalendar
      @properties = DirectoryInfo.create(outer)
      @properties.check_begin_end('VCALENDAR')

      @components = []

      factory = {
        'VEVENT' => Vevent,
        'VTODO' => Vtodo,
        'VJOURNAL' => Vjournal,
        'VTIMEZONE' => Vtimezone,
      }

      inner.each do |component|
        name = component.first
        unless name.name? 'BEGIN'
          raise InvalidEncodingError, "calendar component begins with #{name.name}, instead of BEGIN!", caller
        end

        name = name.value

        vtimezone_exists = false
        if klass = factory[name]
          vtimezone_exists = true if (name == 'VTIMEZONE')
          @components << klass.new(component)
        end
        
        # Create a shortcutted UTC Vtimezone component if there was no VTIMEZONE
        # Element in the ics file. It will respond as a UTC Vtimezone
        @components << Vtimezone.new unless vtimezone_exists
      end
    end
    
    # Push a calendar component onto the calendar.
    # Added Vtimezone as a component R. Berger
    def push(component)
      case component
        when Vevent, Vtodo, Vjournal, Vtimezone
          @components << component
        else
          raise ArgumentError, "can't add a #{component.type} to a calendar", caller
      end
      self
    end
    
    # Added by R. Berger to implement basic timezone parsing functionality 
    class Vtimezone
      attr_reader :components

      include Vpim::Icalendar::Property::Base
      include Vpim::Icalendar::Property::Common
      include Vpim::Icalendar::Property::Priority
      include Vpim::Icalendar::Property::Location
      include Vpim::Icalendar::Property::Resources
      include Vpim::Icalendar::Property::Recurrence

      def initialize(fields=nil) #:nodoc:
        # If there are no fields, then this is a shortcut to make a simple UTC object which
        # Does nothing other than return "UTC" for TZ
        if fields.nil?
          @tzid = "UTC"
          @properties = []
          @components = []
          return
        end
        outer, inner = Vpim.outer_inner(fields)

        @properties = Vpim::DirectoryInfo.create(outer)

        proto_elements = []
        @components = []

        factory = {
          'STANDARD' => StandardTimeRules,
          'DAYLIGHT' => DaylightSavingsTimeRules
        }
        
        inner.each do |item|
          name = item.first
          if name.name? 'BEGIN'
            # Its a component
            name = name.value
            if klass = factory[name]
              @components << klass.new(item)
            end
          else
            puts "proto_elements << #{item.inspect}"
            proto_elements << item
          end
        end
        @elements = proto_elements
      end

      def fields #:nodoc:
        f = @properties.to_a
        last = f.pop
        f.push @elements
        f.push last
      end

      def properties #:nodoc:
        @properties
      end
      
      # Return the tzid string. If this Vtimezone object was a shortcut UTC object, 
      # Then return "UTC" otherwise return the real TZID string
      def tzid
        @tzid.nil? ? properties.field('TZID').value : @tzid
      end
      
      # The array of all supported Vtimezone components. If a class is provided,
      # return only the components of that class.
      #
      # If a block is provided, yield the components instead of returning them.
      #
      # Examples:
      #   timezone.components(Vpim::Icalendar::Vtimezone)
      #   => array of all timezone components
      #
      #   timezone.components(Vpim::Icalendar::Vtimezone::StandardTimeRules)
      #   => array of all timezone Standard Time components
      #
      #   timezone.components(Vpim::Icalendar::Vtimezone::DaylightSavingsTimeRules)
      #   => array of all timezone Daylight Saving Time components
      #
      #   timezone.components(Vpim::Icalendar::Vtimezone) {|c| c... }
      #   => yield all todo components
      #
      #   timezone.components {|c| c... }
      #   => yield all components
      def components(klass=Object) #:yields:component
        # TODO - should this take an interval: t0,t1?

        unless block_given?
          return @components.select{|c| klass === c}.freeze
        end

        @components.each do |c|
          if klass === c
            yield c
          end
        end
        self
      end
      
      # Convert a time or datetime to utc based on the Vtimezone object (self)
      #
      # TODO: Make it work with multiple VTIMEZONEs and actually look up 
      #       the TZID of the time element against the VTIMEZONEs
      #
      # Example Usage:
      #   timezone = cal.components(Vpim::Icalendar::Vtimezone).first
      #   dtstart = cal.components(Vpim::Icalendar::Vevent).first.dtstart
      #   dtstart_utc = timezone.to_utc(dtstart)
      def to_utc(time)
        # Just return it if it already is gmt
        return time if time.gmt?
        standard = components(StandardTimeRules).first
        daylight = components(DaylightSavingsTimeRules).first
        
        # Generate the datetime that represents the start of Standard Time
        std_time_start = gen_start_time(standard, time)

        # Generate the datetime that represents the start of Daylight Savings Time
        day_time_start = gen_start_time(daylight, time)
        
        if time < std_time_start && time >= day_time_start
          # Its withing Daylight Savings Time
          offset_seconds = offset_to_seconds(daylight.tz_offset_to)
        else
          # Its standard time
          offset_seconds = offset_to_seconds(standard.tz_offset_to)
        end

        # Change the time to be the time value at GMT
        t = (time - offset_seconds)
        
        # Hack to get rid of local timezone status in the time object
        utc_time = Time.gm(t.year, t.mon, t.day, t.hour, t.min, t.sec)
        
      end

      # Helper to generate the start datetime of Standard Time or Daylight Savings Time
      def gen_start_time(time_rules, time)
        if (rdate = time_rules.rdate) && time_rules.rrule.nil?
          # If there is just an rdate, just return it
          return rdate
        elsif (rrule = time_rules.rrule) && time_rules.rdate.nil?
          # If there is just an rrule, process it and return a start date based on it
          month = rrule.by['BYMONTH'].to_i
          weekday = rrule.by['BYDAY'][/[A-Za-z]+/]
          weekday_count = rrule.by['BYDAY'][/^[+-]*\d/].to_i
          
          return Date.bywday(time.year, month, Date.str2wday(weekday), weekday_count).to_time.getutc
        else
          # Its got an rdate and an rrule and we don't know how to process that now
          raise RuntimeError, "VTIMEZONE has an rrule and an rdate", caller
        end
        
      end
      # Helper method to convert  a textual offset_string to a positive or negative integer representing 
      # that offset value in seconds
      def offset_to_seconds(offset_string)
        sign = offset_string[/^[-+]/]
        hours = offset_string[1,2].to_i
        min = offset_string[3,4].to_i
        offset_seconds = ((hours * 3600) + (min * 60)) * (sign == '-' ? -1 : 1)
      end
      
      # An 'abstract' class that implements all the methods but would not be used by itself, but instead 
      # would be inhereted by DaylightSavingsTimeRules or StandardTimeRules
      # Since we need to differentiate at the Class level between Daylight and Standard
      # for the factory mechanism and component selectors of the Vtimezone class
      class TimeRules
        include Vpim::Icalendar::Property::Base

        def initialize(fields) #:nodoc:
          outer, inner = Vpim.outer_inner(fields)

          @properties = Vpim::DirectoryInfo.create(outer)

          @elements = inner

        end

        # TODO - derive everything from Icalendar::Component to get this kind of stuff?
        def fields #:nodoc:
          f = @properties.to_a
          last = f.pop
          f.push @elements
          f.push last
        end

        # Accessors
        
        def properties #:nodoc:
          @properties
        end

        def dtstart
          @properties.field('DTSTART').value
        end
        
        def tz_offset_from
          @properties.field('TZOFFSETFROM').value
        end
        
        def tz_offset_to
          @properties.field('TZOFFSETTO').value
        end
        
        def rrule
          return nil if @properties.field('RRULE').nil?
          Vpim::Rrule.new(dtstart, @properties.field('RRULE').value)
        end

        def rdate
          proptime 'RDATE'
          #return nil if @properties.field('RDATE').nil?
          #@properties.field('RDATE').value
        end
      end

      # Contains the fields and methods for VTIMEZONE STANDARD components
      class StandardTimeRules < TimeRules
      end
      
      # Contains the fields and methods for VTIMEZONE DAYLIGHT components
      class DaylightSavingsTimeRules < TimeRules
      end
    end
  end
end