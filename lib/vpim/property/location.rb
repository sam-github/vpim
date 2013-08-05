# -*- encoding : utf-8 -*-
=begin
  Copyright (C) 2008 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

module Vpim
  class Icalendar
    module Property
      module Location
        # Physical location information relevant to the component, or nil if
        # there is no LOCATION property.
        def location
          proptext 'LOCATION'
        end

        # Array of Float, +[ latitude, longitude]+.
        #
        # North of the equator is positive latitude, east of the meridian is
        # positive longitude.
        #
        # See RFC2445 for more info... there are lots of special cases.
        def geo
          prop = @properties.detect { |f| f.name? 'GEO' }
          if prop
            prop = Vpim.decode_list(prop.value_raw, ';') do |item| item.to_f end
          end
          prop
        end
      end
    end

    # add a location property to (v)events. This is specified in the RFC 2445
    module Set
      module Location
        def location(value)
          set_text 'LOCATION', value
        end
      end
    end

  end
end


