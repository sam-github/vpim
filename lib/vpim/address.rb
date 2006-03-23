=begin
  Copyright (C) 2006 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

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
      #
      # FIXME - why case insensitive? Email addresses. Should use a URI library
      # if I can find one and it knows how to do URI comparisons.
      def ==(uri)
        Vpim::Methods.casecmp?(self.uri.to_str, uri.to_str)
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

      def inspect
        "#<Vpim::Icalendar::Address:cn=#{cn.inspect} status=#{partstat} rsvp?=#{rsvp} #{uri.inspect}>"
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
        @field['PARTSTAT'] = status.to_str
        status
      end

      # The value of the RSVP field, either +true+ or +false+. It is used to
      # specify whether there is an expectation of a favor of a reply from the
      # calendar user specified by the property value.
      #
      # TODO - should be #rsvp?
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

