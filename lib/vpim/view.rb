
module Vpim
  module View
    
    SECSPERDAY = 24 * 60 * 60

    # View only events occuring in the next week.
    module Week
      def each #:nodoc:
        t0 = Time.new.to_a
        t0[0] = t0[1] = t0[2] = 0 # sec,min,hour = 0
        t0 = Time.local(*t0)
        t1 = t0 + 7 * SECSPERDAY

        # Need to filter occurrences, too. Create modules for this on the fly.
        vevents = {}
        rrule = Module.new do
          def each
            super(t1) do |t|
              if t + (vevents[self].duration || 0) >= t0
                yield t
              end
            end
          end
        end

        occurrences = Module.new do
          def occurrences
            r = super
            vevents[r] = self
            r.extend rrule
          end
        end

        super do |ve|
          if ve.occurs_in?(t0, t1)
            if ve.respond_to?
              ve.extend occurrences
            end
            yield ve
          end
        end
      end
    end
  end
end

