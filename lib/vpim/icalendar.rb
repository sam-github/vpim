=begin
  $Id: icalendar.rb,v 1.24 2005/01/07 03:32:44 sam Exp $

  Copyright (C) 2005 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'vpim/rfc2425'
require 'vpim/dirinfo'
require 'vpim/rrule'
require 'vpim/vevent'
require 'vpim/vpim'

=begin

  ...            ; y/n    (whether I've seen it in Apple's calendars)
                   name
                   section
                   type/comments


  icalbody = icalprops component

  icalprops =
     prodid /    ; y  PRODID    4.7.3  required, TEXT
     version /   ; y            4.7.4  required, TEXT, "2.0"
     calscal /   ; y            4.7.1  only defined value is GREGORIAN
     method /    ; n  METHOD    4.7.2  used with transport protocols

  component =
     eventc /    ; y  VEVENT    4.6.1
     todoc /     ; y  VTODO     4.6.2
     journalc /  ; n
     freebusyc / ; n
     timezonec / ; n
     
   alarmc        ; y  VALARM  4.6.6  occurs inside a VEVENT or a VTODO

   class         ; y  CLASS     4.8.1.3   private/public/confidentical/... (default=public)

   comment       ; n            4.8.1.4   TEXT
   description   ; y            4.8.1.5   TEXT
   summary       ; y            4.8.1.12  TEXT
   location      ; y            4.8.1.7   TEXT  intended venue
 
   priority      ; n why?       4.8.1.9   INTEGER, why isn't this seen for my TODO items?

   status        ; y            4.8.1.11  TEXT, different values defined for event, todo, journal

      Event: TENTATIVE, CONFIRMED, CANCELLED

      Todo: NEEDS-ACTION, COMPLETED, IN-PROCESS, CANCELLED

      Journal: DRAFT, FINAL, CANCELLED

   dtstart       ; y  DTSTART   4.8.2.4   DATE-TIME is default, value=date can be set
   dtend         ; y  DTEND     4.8.2.2   Unless it has Z (UTC), or a tzid, then it is local-time.

   dtstamp       ; y  DTSTAMP   4.8.7.2   DATE-TIME, creation time, inclusion is mandatory, but what does
     it mean? It seems to be when the icalendar was actually created (as opposed to when the user entered
     the information into the calendar database, for example), but in that case my Apple icalendars should
     have all components having the same DTSTAMP, but they don't!

   duration      ; y  DURATION  4.8.2.5   dur-value

     dur-value  = (["+"] / "-") "P" (dur-date / dur-time / dur-week)

     dur-date   = dur-day [dur-time]
                = 1*DIGIT "D" [ dur-time ]
                
     dur-time   = "T" (dur-hour / dur-minute / dur-second)
                = "T" (
                    1*DIGIT "H" [ 1*DIGIT "M" [ 1*DIGIT "S" ] ] /
                                  1*DIGIT "M" [ 1*DIGIT "S" ]   /
                                                1*DIGIT "S"
                    )

     dur-week   = 1*DIGIT "W"
     dur-day    = 1*DIGIT "D"
     dur-hour   = 1*DIGIT "H" [dur-minute]
     dur-minute = 1*DIGIT "M" [dur-second]
     dur-second = 1*DIGIT "S"

     The EBNF is complicated, because they want to say that /some/ component
     must be present, and that if you have a "T", you need a time after it,
     and that you can't have an hour followed by seconds with no intervening
     minutes... but we don't care about that during decoding, so we rewrite
     the EBNF as:

     dur-value = ["+" / "-"] "P" [ 1*DIGIT "W" ] [ 1*DIGIT "D" ] [ "T" [ 1*DIGIT "H" ]  [ 1*DIGIT "M" ] [ 1*DIGIT "S" ] ]

   dtdue         ; n  DTDUE     4.8.2.3

   uid           ; y  UID       4.8.4.7   TEXT, recommended to generate them in RFC822 form

   rrule         ; y  RRULE     4.8.5.4   RECUR, can occur multiple times!

   

VEVENT Ifx:

  TEXT: summary, description, comment, location, uid

  think about:  uid

  Vevent#status -> The status, upper-case.
  Vevent#status= -> set a new status, only allow the defined statuses!
  Vevent#status?(s) -> check if the status is s

  can contain alarms... should it include an alarms module?

=end

module Vpim
  # An iCalendar.
  #
  # A Calendar is some meta-information followed by a sequence of components.
  #
  # Defined components are Event, Todo, Freebusy, Journal, and Timezone, each
  # of which are represented by their own class, though they share many
  # properties in common. For example, Event and Todo may both contain
  # multiple Alarm components.
  #
  # = Reference
  #
  # The iCalendar format is specified by a series of IETF documents:
  #
  # - link:rfc2445.txt: Internet Calendaring and Scheduling Core Object Specification
  # - link:rfc2446.txt: iCalendar Transport-Independent Interoperability Protocol
  #   (iTIP) Scheduling Events, BusyTime, To-dos and Journal Entries
  # - link:rfc2447.txt: iCalendar Message-Based Interoperability Protocol
  #
  # iCalendar (RFC 2445) is based on vCalendar, but does not appear to be
  # altogether compatible. iCalendar files have VERSION:2.0 and vCalendar have
  # VERSION:1.0.  While much appears to be similar, the recurrence rule syntax,
  # at least, is completely different.
  #
  # iCalendars are usually transmitted in files with <code>.ics</code>
  # extensions.
  class Icalendar
    include Vpim

    # Regular expression strings for the EBNF of RFC 2445
    module Bnf #:nodoc:
      # dur-value = ["+" / "-"] "P" [ 1*DIGIT "W" ] [ 1*DIGIT "D" ] [ "T" [ 1*DIGIT "H" ]  [ 1*DIGIT "M" ] [ 1*DIGIT "S" ] ]
      DURATION = '([-+])?P(\d+W)?(\d+D)?T?(\d+H)?(\d+M)?(\d+S)?'
    end

    private_class_method :new

    # Create a new Icalendar object from +fields+, an array of
    # DirectoryInfo::Field objects.
    #
    # When decoding Calendar data, you would usually use Icalendar.decode(),
    # which decodes the data into the field arrays, and calls this method
    # for each Calendar it finds.
    def initialize(fields) #:nodoc:
      # seperate into the outer-level fields, and the arrays of component
      # fields
      outer, inner = Vpim.outer_inner(fields)

      # Make a dirinfo out of outer, and check its an iCalendar
      @properties = DirectoryInfo.create(outer)
      @properties.check_begin_end('VCALENDAR')

      # Categorize the components
      @vevents = []
      @vtodos  = []
      @others = []

      inner.each do |component|
        # First field in every component should be a "BEGIN:".
        name = component.first
        if ! name.name? 'begin'
          raise InvalidEncodingError, "calendar component begins with #{name.name}, instead of BEGIN!"
        end

        name = name.value.upcase

        case name
          when 'VEVENT'    then @vevents << Vevent.new(component)
          when 'VTODO'     then @vtodos  << Vtodo.new(component)
          else @others << component
        end
      end
    end

    # Create a new Icalendar object with the minimal set of fields for a valid
    # Calendar. If specified, +fields+ must be an array of
    # DirectoryInfo::Field objects to add. They can override the the default
    # Calendar fields, so, for example, this can be used to set a custom PRODID field.
    #
    # TODO - allow hash args like Vevent.create
    def Icalendar.create(fields=[])
      di = DirectoryInfo.create( [ DirectoryInfo::Field.create('VERSION', '2.0') ], 'VCALENDAR' )

      DirectoryInfo::Field.create_array(fields).each { |f| di.push_unique f }

      di.push_unique DirectoryInfo::Field.create('PRODID',   "-//Ensemble Independant//vPim #{Vpim.version}//EN")
      di.push_unique DirectoryInfo::Field.create('CALSCALE', "Gregorian")

      new(di.to_a)
    end

    # Create a new Icalendar object with a protocol method of REPLY.
    #
    # Meeting requests, and such, are Calendar containers with a protocol
    # method of REQUEST, and contains some number of Events, Todos, etc.,
    # that may need replying to. In order to reply to any of these components
    # of a request, you must first build a Calendar object to hold your reply
    # components.
    #
    # This method builds the reply Calendar, you then will add to it replies
    # to the specific components of the request Calendar that you are replying
    # to. If you have any particular fields that you want to be in the
    # Calendar, other than the defaults, then can be supplied as +fields+, an
    # array of Field objects.
    def Icalendar.create_reply(fields=[])
      fields << DirectoryInfo::Field.create('METHOD', 'REPLY')

      Icalendar.create(fields)
    end

    # Encode the Calendar as a string. The width is the maximum width of the
    # encoded lines, it can be specified, but is better left to the default.
    #
    # TODO - only does top-level now, needs to add the events/todos/etc.
    def encode(width=nil)
      # We concatenate the fields of all objects, create a DirInfo, then
      # encode it.
      di = DirectoryInfo.create(self.fields.flatten)
      di.encode(width)
    end

    # Used during encoding.
    def fields # :nodoc:
      fields = @properties.to_a

      last = fields.pop

      @vevents.each { |c| fields << c.fields }
      @vtodos.each  { |c| fields << c.fields }
      @others.each  { |c| fields << c.fields }

      fields << last
    end

    alias to_s encode

    # Push a calendar component onto the calendar.
    def push(component)
      case component
        when Vevent
          @vevents << component
        when Vtodo
          @vtodos << component
        else
          raise ArgumentError, "can't add component type #{component.type} to a calendar"
      end
    end

    # Check if the protocol method is +method+
    def protocol?(method)
      protocol == method.upcase
    end

    def Icalendar.decode_duration(str) #:nodoc:
      unless match = %r{\s*#{Bnf::DURATION}\s*}.match(str)
        raise InvalidEncodingError, "duration not valid (#{str})"
      end
      dur = 0

      # Remember: match[0] is the whole match string, match[1] is $1, etc.

      # Week
      if match[2]
        dur = match[2].to_i
      end
      # Days
      dur *= 7
      if match[3]
        dur += match[3].to_i
      end
      # Hours
      dur *= 24
      if match[4]
        dur += match[4].to_i
      end
      # Minutes
      dur *= 60
      if match[5]
        dur += match[5].to_i
      end
      # Seconds
      dur *= 60
      if match[6]
        dur += match[6].to_i
      end

      if match[1] && match[1] == '-'
        dur = -dur
      end

      dur
    end

    # Decode iCalendar data into an array of Icalendar objects.
    #
    # Since iCalendars are self-delimited (by a BEGIN:VCALENDAR and an
    # END:VCALENDAR), multiple iCalendars can be concatenated into a single
    # file.
    #
    # cal must be either a string, or an IO object.
    def Icalendar.decode(cal)
      if cal.respond_to? :to_str
        string = cal.to_str
      elsif cal.kind_of? IO
        string = cal.read(nil)
      else
        raise ArgumentError, "Icalendar.decode cannot be called with a #{cal.type}"
      end

      entities = Vpim.expand(Vpim.decode(string))

      # Since all iCalendars must have a begin/end, the top-level should
      # consist entirely of entities/arrays, even if its a single iCalendar.
      if entities.detect { |e| ! e.kind_of? Array }
        raise "Not a valid iCalendar"
      end

      calendars = []

      entities.each do |e|
        calendars << new(e)
      end

      calendars
    end

    # The iCalendar version multiplied by 10 as an Integer.  If no VERSION field
    # is present (which is non-conformant), nil is returned. iCalendar must
    # have a version of 20, and vCalendar would have a version of 10.
    def version
      v = @properties['VERSION']

      unless v
        raise InvalidEncodingError, "Invalid calendar, no version field!"
      end

      v = v.to_f * 10
      v = v.to_i
    end

    # The value of the PRODID field, an unstructured string meant to
    # identify the software which encoded the Calendar data.
    def producer
      #f = @properties.field('PRODID')
      #f && f.to_text
      @properties.text('PRODID').first
    end

    # The value of the METHOD field. Protocol methods are used when iCalendars
    # are exchanged in a calendar messaging system, such as iTIP or iMIP. When
    # METHOD is not specified, the Calendar object is merely being used to
    # transport a snapshot of some calendar information; without the intention
    # of conveying a scheduling semantic.
    #
    # Note that this can't be called 'method', that name is reserved.
    def protocol
      m = @properties['METHOD']
      m ? m.upcase : m
    end

    # The array of all calendar events (each is a Vevent).
    #
    # TODO - should this take an interval: t0,t1?
    def events
      @vevents
    end

    # The array of all calendar todos (each is a Vtodo).
    def todos
      @vtodos
    end
  end

end

=begin

Notes on a CAL-ADDRESS

When used with ATTENDEE, the parameters are:
  CN
  CUTYPE
  DELEGATED-FROM
  DELEGATED-TO
  DIR
  LANGUAGE
  MEMBER
  PARTSTAT
  ROLE
  RSVP
  SENT-BY

When used with ORGANIZER, the parameters are:
  CN
  DIR
  LANGUAGE
  SENT-BY


What I've seen in Notes invitations, and iCal responses:
  ROLE
  PARTSTAT
  RSVP
  CN

Support these last 4, for now.

=end

module Vpim
  class Icalendar
    # Used to represent calendar fields containing CAL-ADDRESS values.
    # The organizer or the attendees of a calendar event are examples of such
    # a field.
    #
    # Example:
    #   ORGANIZER;CN="A. Person":mailto:a_person@example.com
    #   ATTENDEE;ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION
    #    ;CN="Sam Roberts";RSVP=TRUE:mailto:SRoberts@example.com
    #
    class Address

      # Create an Address from a DirectoryInfo::Field, +field+.
      #
      # TODO - make private, and split into the encode/decode/create trinity.
      def initialize(field)
        unless field.value
          raise ArgumentError
        end

        @field = field
      end

      # Return a representation of this Address as a DirectoryInfo::Field.
      def field
        @field.copy
      end

      # Create a copy of Address. If the original Address was frozen, this one
      # won't be.
      def copy
        Marshal.load(Marshal.dump(self))
      end

      # Addresses in a CAL-ADDRESS are represented as a URI, usually a mailto URI.
      def uri
        @field.value
      end

      # Return true if the +uri+ is == to this address' URI. The comparison
      # is case-insensitive.
      def ==(uri)
        self.uri.downcase == uri.downcase
      end

      # The common or displayable name associated with the calendar address,
      # or nil if there is none.
      def cn
        return nil unless n = @field.param('CN')

        # FIXME = the CN param may have no value, which is an error, but don't try
        # to decode it, return either nil, or InvalidEncoding
        Vpim.decode_text(n.first)
      end

      # A string representation of an address, using the common name, and the
      # URI. The URI protocol is stripped if it's "mailto:".
      # 
      # TODO - this needs to properly escape the cn string!
      def to_s
        u = uri
        u.gsub!(/^mailto: */i, '')

        if cn
          "\"#{cn}\" <#{uri}>"
        else
          uri
        end
      end

      # The participation role for the calendar user specified by the address.
      #
      # The standard roles are:
      # - CHAIR Indicates chair of the calendar entity
      # - REQ-PARTICIPANT Indicates a participant whose participation is required
      # - OPT-PARTICIPANT Indicates a participant whose participation is optional
      # - NON-PARTICIPANT Indicates a participant who is copied for information purposes only
      #
      # The default role is REQ-PARTICIPANT, returned if no ROLE parameter was
      # specified.
      def role
        return 'REQ-PARTICIPANT' unless r = @field.param('ROLE')
        r.first.upcase
      end

      # The participation status for the calendar user specified by the
      # property PARTSTAT, a String.
      #
      # These are the participation statuses for an Event:
      # - NEEDS-ACTION Event needs action
      # - ACCEPTED Event accepted
      # - DECLINED Event declined
      # - TENTATIVE Event tentatively accepted
      # - DELEGATED Event delegated
      #
      # Default is NEEDS-ACTION.
      #
      # TODO - make the default depend on the component type.
      def partstat
        return 'NEEDS-ACTION' unless r = @field.param('PARTSTAT')
        r.first.upcase
      end

      # Set or change the participation status of the address, the PARTSTAT,
      # to +status+.
      #
      # See #partstat.
      def partstat=(status)
        @field['partstat'] = status.to_str
        status
      end

      # The value of the RSVP field, either +true+ or +false+. It is used to
      # specify whether there is an expectation of a favor of a reply from the
      # calendar user specified by the property value.
      def rsvp
        return false unless r = @field.param('RSVP')
        r = r.first
        return false unless r
        case r
          when /TRUE/i then true
          when /FALSE/i then false
          else raise InvalidEncodingError, "RSVP param value not TRUE/FALSE: #{r}"
        end
      end
    end
  end
end

