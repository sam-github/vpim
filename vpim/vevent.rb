=begin
  $Id: vevent.rb,v 1.12 2005/01/21 04:09:55 sam Exp $

  Copyright (C) 2005 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'vpim/dirinfo'
require 'vpim/field'
require 'vpim/rfc2425'
require 'vpim/vpim'

=begin
A vTodo that is done:

BEGIN:VTODO
COMPLETED:20040303T050000Z
DTSTAMP:20040304T011707Z
DTSTART;TZID=Canada/Eastern:20030524T115238
SEQUENCE:2
STATUS:COMPLETED
SUMMARY:Wash Car
UID:E7609713-8E13-11D7-8ACC-000393AD088C
END:VTODO

BEGIN:VTODO
DTSTAMP:20030909T015533Z
DTSTART;TZID=Canada/Eastern:20030808T000000
SEQUENCE:1
SUMMARY:Renew Passport
UID:EC76B256-BBE9-11D7-8401-000393AD088C
END:VTODO


=end

module Vpim
  class Icalendar
    class Vtodo
      def initialize(fields) #:nodoc:
        @fields = fields

        outer, inner = Vpim.outer_inner(fields)

        @properties = Vpim::DirectoryInfo.create(outer)

        @elements = inner

        # TODO - don't get properties here, put the accessor in a module,
        # which can cache the results.

        @summary       = @properties.text('SUMMARY').first
        @description   = @properties.text('DESCRIPTION').first
        @comment       = @properties.text('COMMENT').first
        @location      = @properties.text('LOCATION').first
        @status        = @properties.text('STATUS').first
        @uid           = @properties.text('UID').first
        @priority      = @properties.text('PRIORITY').first

        # See "TODO - fields" in dirinfo.rb
        @dtstamp       = @properties.field('dtstamp')
        @dtstart       = @properties.field('dtstart')
        @dtend         = @properties.field('dtend')
        @duration      = @properties.field('duration')
        @due           = @properties.field('due')
        @rrule         = @properties['rrule']

        # Need to seperate status-handling out into a module...
        @status_values = [ 'COMPLETED' ];

      end

      attr_reader :description, :summary, :comment, :location
      attr_reader :properties, :fields # :nodoc:

      # Create a new Vtodo object.
      #
      # If specified, +fields+ must be either an array of Field objects to
      # add, or a Hash of String names to values that will be used to build
      # Field objects. The latter is a convenient short-cut allowing the Field
      # objects to be created for you when called like:
      #
      #   Vtodo.create('SUMMARY' => "buy mangos")
      #
      # TODO - maybe todos are usually created in a particular way? I can
      # make it easier. Ideally, I would like to make it hard to encode an invalid
      # Event.
      def Vtodo.create(fields=[])
        di = DirectoryInfo.create([], 'VTODO')

        Vpim::DirectoryInfo::Field.create_array(fields).each { |f| di.push_unique f }

        new(di.to_a)
      end

=begin
I think that the initialization shouldn't be done in the #initialize, so, for example,
  @status = @properties.text('STATUS').first
should be in the method below.

That way, I can construct a Vtodo by just including a module for each field that is allowed
in a Vtodo, simply.
=end
      def status
        if(!@status); return nil; end

        s = @status.upcase

        unless @status_values.include?(s)
          raise Vpim::InvalidEncodingError, "Invalid status '#{@status}'"
        end

        s
      end

      # +priority+ is a number from 1 to 9, with 1 being the highest and 0
      # meaning "no priority", equivalent to not specifying the PRIORITY field.
      # Other values are reserved by RFC2446.
      def priority
        p = @priority ? @priority.to_i : 0

        if( p < 0 || p > 9 )
          raise Vpim::InvalidEncodingError, 'Invalid priority #{@priority} - it must be 0-9!'
        end
        p
      end
    end
  end
end

module Vpim
  class Icalendar
    class Vevent
      def initialize(fields) #:nodoc:
        @fields = fields

        outer, inner = Vpim.outer_inner(fields)

        @properties = Vpim::DirectoryInfo.create(outer)

        @elements = inner

        # TODO - don't get properties here, put the accessor in a module,
        # which can cache the results.

        @summary       = @properties.text('SUMMARY').first
        @description   = @properties.text('DESCRIPTION').first
        @comment       = @properties.text('COMMENT').first
        @location      = @properties.text('LOCATION').first
        @status        = @properties.text('STATUS').first
        @uid           = @properties.text('UID').first

        # See "TODO - fields" in dirinfo.rb
        @dtstamp       = @properties.field('dtstamp')
        @dtstart       = @properties.field('dtstart')
        @dtend         = @properties.field('dtend')
        @duration      = @properties.field('duration')
        @rrule         = @properties['rrule']

        # Need to seperate status-handling out into a module...
        @status_values = [ 'TENTATIVE', 'CONFIRMED', 'CANCELLED' ];

      end

      # Create a new Vevent object. All events must have a DTSTART field,
      # specify it as either a Time or a Date in +start+, it defaults to "now"
      # (is this useful?).
      #
      # If specified, +fields+ must be either an array of Field objects to
      # add, or a Hash of String names to values that will be used to build
      # Field objects. The latter is a convenient short-cut allowing the Field
      # objects to be created for you when called like:
      #
      #   Vevent.create(Date.today, 'SUMMARY' => "today's event")
      #
      # TODO - maybe events are usually created in a particular way? With a
      # start/duration or a start/end? Maybe I can make it easier. Ideally, I
      # would like to make it hard to encode an invalid Event.
      def Vevent.create(start = Time.now, fields=[])
        dtstart = DirectoryInfo::Field.create('DTSTART', start)
        di = DirectoryInfo.create([ dtstart ], 'VEVENT')

        Vpim::DirectoryInfo::Field.create_array(fields).each { |f| di.push_unique f }

        new(di.to_a)
      end

      attr_reader :description, :summary, :comment, :location
      attr_reader :properties, :fields # :nodoc:

      #--
      # The methods below should be shared, somehow, by all calendar components, not just Events.
      #++

      # Accept an event invitation. The +invitee+ is the Address that wishes
      # to accept the event invitation as confirmed.
      def accept(invitee)
        # The event created is identical to this one, but
        # - without the attendees
        # - with the invitee added with a PARTSTAT of ACCEPTED
        invitee = invitee.copy
        invitee.partstat = 'ACCEPTED'

        fields = []

        @properties.each_with_index do
          |f,i|

          # put invitee in as field[1]
          fields << invitee.field if i == 1
          
          fields << f unless f.name? 'ATTENDEE'
        end

        Vevent.new(fields)
      end

      # Status values are not rejected during decoding. However, if the
      # status is requested, and it's value is not one of the defined
      # allowable values, an exception is raised.
      def status
        if(!@status); return nil; end

        s = @status.upcase

        unless @status_values.include?(s)
          raise Vpim::InvalidEncodingError, "Invalid status '#{@status}'"
        end

        s
      end

      # TODO - def status? ...

      # TODO - def status= ...

      # The unique identifier of this calendar component, a string. It cannot be
      # nil, if it is not found in the component, the calendar is malformed, and
      # this method will raise an exception.
      def uid
        if(!@uid)
          raise Vpim::InvalidEncodingError, 'Invalid component - no UID field was found!'
        end

        @uid
      end

      # The time stamp for this calendar component. Describe what this is....
      # This field is required!
      def dtstamp
        if(!@dtstamp)
          raise Vpim::InvalidEncodingError, 'Invalid component - no DTSTAMP field was found!'
        end

        @dtstamp.to_time.first
      end

      # The start time for this calendar component. Describe what this is....
      # This field is required!
      def dtstart
        if(!@dtstart)
          raise Vpim::InvalidEncodingError, 'Invalid component - no DTSTART field was found!'
        end

        @dtstart.to_time.first
      end

=begin
      # Set the start time for the event to +start+, a Time object.
      # TODO - def dtstart=(start) ... start should be allowed to be Time/Date/DateTime
=end

      # The duration in seconds of a Event, Todo, or Vfreebusy component, or
      # for Alarms, the delay period prior to repeating the alarm. The
      # duration is calculated from the DTEND and DTBEGIN fields if the
      # DURATION field is not present. Durations of zero seconds are possible.
      def duration
        if(!@duration)
          return nil unless @dtend

          b = dtstart
          e = dtend

          return (e - b).to_i
        end

        Icalendar.decode_duration(@duration.value_raw)
      end

      # The end time for this calendar component. For an Event, if there is no
      # end time, then nil is returned, and the event takes up no time.
      # However, the end time will be calculated from the event duration, if
      # present.
      def dtend
        if(@dtend)
          @dtend.to_time.first
        elsif duration
            dtstart + duration
        else
          nil
        end
      end

      # The recurrence rule, if any, for this event. Recurrence starts at the
      # DTSTART time.
      def rrule
        @rrule
      end

      # The times this event occurs, as a Vpim::Rrule.
      #
      # Note: the event may occur only once.
      #
      # Note: occurences are currently calculated only from DTSTART and RRULE,
      # no allowance for EXDATE or other fields is made.
      def occurences
        Vpim::Rrule.new(dtstart, @rrule)
      end

      # Check if this event overlaps with the time period later than or equal to +t0+, but
      # earlier than +t1+.
      def occurs_in?(t0, t1)
        occurences.each_until(t1).detect { |t| tend = t + (duration || 0); tend > t0 }
      end

      # Return the event organizer, an object of Icalendar::Address (or nil if
      # there is no ORGANIZER field).
      #
      # TODO - verify that it is illegal for there to be more than one
      # ORGANIZER, if more than one is allowed, this needs to return an array.
      def organizer
        unless instance_variables.include? "@organizer"
          @organizer = @properties.field('ORGANIZER')

          if @organizer
            @organizer = Icalendar::Address.new(@organizer)
          end
        end
        @organizer.freeze
      end

      # Return an array of attendees, an empty array if there are none. The
      # attendees are objects of Icalendar::Address. If +uri+ is specified
      # only the return the attendees with this +uri+.
      def attendees(uri = nil)
        unless instance_variables.include? "@attendees"
          @attendees = @properties.enum_by_name('ATTENDEE').map { |a| Icalendar::Address.new(a).freeze }
          @attendees.freeze
        end
        if uri
          @attendees.select { |a| a == uri } .freeze
        else
          @attendees
        end
      end

      # Return true if the +uri+, usually a mailto: URI, is an attendee.
      def attendee?(uri)
        attendees.include? uri
      end

      # CONTACT - value is text, parameters are ALTREP and LANGUAGE.
      #
      # textual contact information, or an altrep referring to a URI pointing
      # at a vCard or LDAP entry...
    end
  end
end

