# -*- encoding : utf-8 -*-
=begin
  Copyright (C) 2008 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'vpim/dirinfo'
require 'vpim/field'
require 'vpim/rfc2425'
require 'vpim/vpim'
require 'vpim/property/base'
require 'vpim/property/common'
require 'vpim/property/priority'
require 'vpim/property/location'
require 'vpim/property/resources'
require 'vpim/property/recurrence'

module Vpim
  class Icalendar

    class Vtodo
      include Vpim::Icalendar::Property::Base
      include Vpim::Icalendar::Property::Common
      include Vpim::Icalendar::Property::Priority
      include Vpim::Icalendar::Property::Location
      include Vpim::Icalendar::Property::Resources
      include Vpim::Icalendar::Property::Recurrence

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

      def properties #:nodoc:
        @properties
      end

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

      # The duration in seconds of a Todo, or nil if unspecified. If the
      # DURATION field is not present, but the DUE field is, the duration is
      # calculated from DTSTART and DUE. Durations of zero seconds are
      # possible.
      def duration
        propduration 'DUE'
      end

      # The time at which this Todo is due to be completed. If the DUE field is not present,
      # but the DURATION field is, due will be calculated from DTSTART and DURATION.
      def due
        propend 'DUE'
      end

      # The date and time that a to-do was actually completed, a Time.
      def completed
        proptime 'COMPLETED'
      end

      # The percentage completetion of the to-do, between 0 and 100. 0 means it hasn't
      # started, 100 that it has been completed.
      #
      # TODO - the handling of this property isn't tied to either COMPLETED: or
      # STATUS:, but perhaps it should be?
      def percent_complete
        propinteger 'PERCENT-COMPLETE'
      end

    end

  end
end

