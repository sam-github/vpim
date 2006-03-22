module Vpim
  class Icalendar
    module Property #:nodoc:

      # FIXME - these should be part of Dirinfo
      module Base
        # Value of first property with name +name+
        def propvalue(name) #:nodoc:
          prop = @properties.detect { |f| f.name? name }
          if prop
            prop = prop.value
          end
          prop
        end

        # Array of values of all properties with name +name+
        def propvaluearray(name) #:nodoc:
          @properties.select{ |f| f.name? name }.map{ |p| p.value }
        end


        def propinteger(name) #:nodoc:
          prop = @properties.detect { |f| f.name? name }
          if prop
            prop = Vpim.decode_integer(prop.value)
          end
          prop
        end

        def proptoken(name, allowed, default_token = nil) #:nodoc:
          prop = propvalue name

          if prop
            prop = prop.to_str.upcase
            unless allowed.include?(prop)
              raise Vpim::InvalidEncodingError, "Invalid #{name} value '#{prop}'"
            end
          else
            prop = default_token
          end

          prop
        end

        # Value as DATE-TIME or DATE of object of first property with name +name+
        def proptime(name) #:nodoc:
          prop = @properties.detect { |f| f.name? name }
          if prop
            prop = prop.to_time.first
          end
          prop
        end

        # Value as TEXT of first property with name +name+
        def proptext(name) #:nodoc:
          prop = @properties.detect { |f| f.name? name }
          if prop
            prop = prop.to_text
          end
          prop
        end

        # Array of values as TEXT of all properties with name +name+
        def proptextarray(name) #:nodoc:
          @properties.select{ |f| f.name? name }.map{ |p| p.to_text }
        end

        # Array of values as TEXT list of all properties with name +name+
        def proptextlistarray(name) #:nodoc:
          @properties.select{ |f| f.name? name }.map{ |p| Vpim.decode_text_list(p.value_raw) }.flatten
        end

      end
    end
  end
end

