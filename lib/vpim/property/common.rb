require 'vpim/attachment'

module Vpim
  class Icalendar
    module Property

      # Properties common to Vevent, Vtodo, and Vjournal.
      module Common

        # This property defines the access classification for a calendar
        # component.
        #
        # An access classification is only one component of the general
        # security system within a calendar application. It provides a method
        # of capturing the scope of the access the calendar owner intends for
        # information within an individual calendar entry. The access
        # classification of an individual iCalendar component is useful when
        # measured along with the other security components of a calendar
        # system (e.g., calendar user authentication, authorization, access
        # rights, access role, etc.). Hence, the semantics of the individual
        # access classifications cannot be completely defined by this memo
        # alone. Additionally, due to the "blind" nature of most exchange
        # processes using this memo, these access classifications cannot serve
        # as an enforcement statement for a system receiving an iCalendar
        # object.  Rather, they provide a method for capturing the intention of
        # the calendar owner for the access to the calendar component.
        #
        # Property Name: CLASS
        #
        # Property Value: one of "PUBLIC", "PRIVATE", "CONFIDENTIAL", default
        # is "PUBLIC" if no CLASS property is found.
        def access_class
          proptoken 'CLASS', ["PUBLIC", "PRIVATE", "CONFIDENTIAL"], "PUBLIC"
        end

        def created
          proptime 'CREATED'
        end

        # Description of the calendar component, or nil if there is no
        # description.
        def description
          proptext 'DESCRIPTION'
        end

        # Revision sequence number of the calendar component, or nil if there
        # is no SEQUENCE; property.
        def sequence
          propinteger 'SEQUENCE'
        end

        # The time stamp for this calendar component.
        def dtstamp
          proptime 'DTSTAMP'
        end

        # The start time for this calendar component.
        def dtstart
          proptime 'DTSTART'
        end

        def lastmod
          proptime 'LAST-MODIFIED'
        end

        # Return the event organizer, an object of Icalendar::Address (or nil if
        # there is no ORGANIZER field).
        def organizer
          organizer = @properties.field('ORGANIZER')

          if organizer
            organizer = Icalendar::Address.new(organizer)
          end

          organizer.freeze
        end

=begin
recurid
seq
=end

        # Status values are not rejected during decoding. However, if the
        # status is requested, and it's value is not one of the defined
        # allowable values, an exception is raised.
        def status
          case self
          when Vpim::Icalendar::Vevent
            proptoken 'STATUS', ['TENTATIVE', 'CONFIRMED', 'CANCELLED']

          when Vpim::Icalendar::Vtodo
            proptoken 'STATUS', ['NEEDS-ACTION', 'COMPLETED', 'IN-PROCESS', 'CANCELLED']

          when Vpim::Icalendar::Vevent
            proptoken 'STATUS', ['DRAFT', 'FINAL', 'CANCELLED']
          end
        end

        # TODO - def status? ...

        # TODO - def status= ...

        # Summary description of the calendar component, or nil if there is no
        # SUMMARY property.
        def summary
          proptext 'SUMMARY'
        end

        # The unique identifier of this calendar component, a string.
        def uid
          proptext 'UID'
        end

        def url
          propvalue 'URL'
        end

        # Return an array of attendees, an empty array if there are none. The
        # attendees are objects of Icalendar::Address. If +uri+ is specified
        # only the return the attendees with this +uri+.
        def attendees(uri = nil)
          attendees = @properties.enum_by_name('ATTENDEE').map { |a| Icalendar::Address.new(a).freeze }
          attendees.freeze
          if uri
            attendees.select { |a| a == uri }
          else
            attendees
          end
        end

        # Return true if the +uri+, usually a mailto: URI, is an attendee.
        def attendee?(uri)
          attendees.include? uri
        end

        # This property defines the categories for a calendar component.
        #
        # Property Name: CATEGORIES
        #
        # Value Type: TEXT
        #
        # Ruby Type: Array of String
        #
        # This property is used to specify categories or subtypes of the
        # calendar component. The categories are useful in searching for a
        # calendar component of a particular type and category.
        def categories
          proptextlistarray 'CATEGORIES'
        end

        def comments
          proptextarray 'COMMENT'
        end

        def contacts
          proptextarray 'CONTACT'
        end

        # Attachments, an Array of Icalendar::Attachment objects.
        def attachments
          @properties.enum_by_name('ATTACH').map do |f|
            value = f.value
            format = f['FMTTYPE']
            format = format.first if format
            type = f['VALUE']
            if type
              type = type.first
            end
            
            if Vpim::Methods.casecmp?(type, 'BINARY')
              Attachment.new(nil, value, format)
            else
              Attachment.new(value, nil, format)
            end
          end
        end

      end
    end
  end
end


