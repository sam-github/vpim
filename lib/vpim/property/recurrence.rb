=begin
  Copyright (C) 2008 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

module Vpim
  class Icalendar
    module Property

      # Occurrences are calculated from DTSTART: and RRULE:. If there is no
      # RRULE:, the component recurs only once, at the start time.
      #
      # Limitations:
      #
      # Only a single RRULE: is currently supported, this is the most common
      # case.
      module Recurrence
        # The times this event occurs, as a Vpim::Rrule. If a block is
        # provided, Rrule#each is called with the block.
        def occurrences(&block) #:yield: occurrence time
          start = dtstart
          unless start
            raise ArgumentError, "Components with no DTSTART: don't have occurrences!"
          end
          r = Vpim::Rrule.new(start, propvalue('RRULE'))
          if block_given?
            r.each(&block)
          end
          r
        end

        alias occurences occurrences #:nodoc: backwards compatibility

        # Check if this event overlaps with the time period later than or equal to +t0+, but
        # earlier than +t1+.
        def occurs_in?(t0, t1)
          occurrences.each_until(t1).detect do |t|
            tend = t + (duration || 0)
            tend > t0
          end
        end

        def rdates
          Vpim.decode_date_time_list(propvalue('RDATE'))
        end

      end
    end
  end
end


