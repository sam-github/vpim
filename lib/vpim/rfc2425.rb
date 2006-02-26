=begin
  Copyright (C) 2006 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'vpim/vpim'

module Vpim
  # Contains regular expression strings for the EBNF of RFC 2425.
  module Bnf #:nodoc:

    # 1*(ALPHA / DIGIT / "-")
    # Note: I think I can add A-Z here, and get rid of the "i" matches elsewhere.
    # Note: added '_' to allowed because its produced by Notes - X-LOTUS-CHILD_UID
    NAME    = '[-a-z0-9_]+'

    # <"> <Any character except CTLs, DQUOTE> <">
    QSTR    = '"([^"]*)"'
     
    # *<Any character except CTLs, DQUOTE, ";", ":", ",">
    PTEXT   = '([^";:,]+)'
      
    # param-value = ptext / quoted-string
    PVALUE  = "(?:#{QSTR}|#{PTEXT})"
    
    # param = name "=" param-value *("," param-value)
    # Note: v2.1 allows a type or encoding param-value to appear without the type=
    # or the encoding=. This is hideous, but we try and support it, if there
    # is no "=", then $2 will be "", and we will treat it as a v2.1 param.
    PARAM = ";(#{NAME})(=?)((?:#{PVALUE})?(?:,#{PVALUE})*)"

    # V3.0: contentline  =   [group "."]  name *(";" param) ":" value
    # V2.1: contentline  = *( group "." ) name *(";" param) ":" value
    #
    # We accept the V2.1 syntax for backwards compatibility.
    #LINE = "((?:#{NAME}\\.)*)?(#{NAME})([^:]*)\:(.*)"
    LINE = "^((?:#{NAME}\\.)*)?(#{NAME})((?:#{PARAM})*):(.*)$"

    # date = date-fullyear ["-"] date-month ["-"] date-mday
    # date-fullyear = 4 DIGIT
    # date-month = 2 DIGIT
    # date-mday = 2 DIGIT
    DATE = '(\d\d\d\d)-?(\d\d)-?(\d\d)'

    # time = time-hour [":"] time-minute [":"] time-second [time-secfrac] [time-zone]
    # time-hour = 2 DIGIT
    # time-minute = 2 DIGIT
    # time-second = 2 DIGIT
    # time-secfrac = "," 1*DIGIT
    # time-zone = "Z" / time-numzone
    # time-numzome = sign time-hour [":"] time-minute
    TIME = '(\d\d):?(\d\d):?(\d\d)(\.\d+)?(Z|[-+]\d\d:?\d\d)?'
  end
end

module Vpim
  # Split on \r\n or \n to get the lines, unfold continued lines (they
  # start with ' ' or \t), and return the array of unfolded lines.
  #
  # This also supports the (invalid) encoding convention of allowing empty
  # lines to be inserted for readability - it does this by dropping zero-length
  # lines.
  def Vpim.unfold(card) #:nodoc:
      unfolded = []

      card.each do |line|
        line.chomp!
        # If it's a continuation line, add it to the last.
        # If it's an empty line, drop it from the input.
        if( line =~ /^[ \t]/ )
          unfolded[-1] << line[1, line.size-1]
        elsif( line =~ /^$/ )
        else
          unfolded << line
        end
      end

      unfolded
  end

  # Convert a +sep+-seperated list of values into an array of values.
  def Vpim.decode_list(value, sep = ',') # :nodoc:
    list = []
    
    value.each(sep) {
      |item|
      list << yield(item) unless item =~ %r{^\s*#{sep}?$}
    }
    list
  end

  # Convert a RFC 2425 date into an array of [year, month, day].
  def Vpim.decode_date(v) # :nodoc:
    unless v =~ %r{\s*#{Bnf::DATE}\s*}
      raise Vpim::InvalidEncodingError, "date not valid (#{v})"
    end
    [$1.to_i, $2.to_i, $3.to_i]
  end

  # Note in the following the RFC2425 allows yyyy-mm-ddThh:mm:ss, but RFC2445
  # does not. I choose to encode to the subset that is valid for both.

  # Encode a Date object as "yyyymmdd".
  def Vpim.encode_date(d) # :nodoc:
     "%0.4d%0.2d%0.2d" % [ d.year, d.mon, d.day ]
  end

  # Encode a Date object as "yyyymmdd".
  def Vpim.encode_time(d) # :nodoc:
     "%0.4d%0.2d%0.2d" % [ d.year, d.mon, d.day ]
  end

  # Encode a Time or DateTime object as "yyyymmddThhmmss"
  def Vpim.encode_date_time(d) # :nodoc:
     "%0.4d%0.2d%0.2dT%0.2d%0.2d%0.2d" % [ d.year, d.mon, d.day, d.hour, d.min, d.sec ]
  end

  # Convert a RFC 2425 time into an array of [hour,min,sec,secfrac,timezone]
  def Vpim.decode_time(v) # :nodoc:
    unless match = %r{\s*#{Bnf::TIME}\s*}.match(v)
      raise Vpim::InvalidEncodingError, "time not valid (#{v})"
    end
    hour, min, sec, secfrac, tz = match.to_a[1..5]

    [hour.to_i, min.to_i, sec.to_i, secfrac ? secfrac.to_f : 0, tz]
  end

  # Convert a RFC 2425 date-time into an array of [hour,min,sec,secfrac,timezone]
  def Vpim.decode_date_time(v) # :nodoc:
    unless match = %r{\s*#{Bnf::DATE}T#{Bnf::TIME}\s*}.match(v)
      raise Vpim::InvalidEncodingError, "date-time '#{v}' not valid"
    end
    year, month, day, hour, min, sec, secfrac, tz = match.to_a[1..8]

    [
      # date
      year.to_i, month.to_i, day.to_i,
      # time
      hour.to_i, min.to_i, sec.to_i, secfrac ? secfrac.to_f : 0, tz
    ]
  end

  # Vpim.decode_boolean
  #
  # float
  #
  # float_list
  #
  # integer
  #
  # integer_list
  #
  # text_list

  # Convert a RFC 2425 date-list into an array of dates.
  def Vpim.decode_date_list(v) # :nodoc:
    dates = Vpim.decode_list(v) { |date| Vpim.decode_date(date) }
  end

  # Convert a RFC 2425 time-list into an array of times.
  def Vpim.decode_time_list(v) # :nodoc:
    times = Vpim.decode_list(v) { |time| Vpim.decode_time(time) }
  end

  # Convert a RFC 2425 date-time-list into an array of date-times.
  def Vpim.decode_date_time_list(v) # :nodoc:
    datetimes = Vpim.decode_list(v) { |datetime| Vpim.decode_date_time(datetime) }
  end

  # Convert RFC 2425 text into a String.
  # \\ -> \
  # \n -> NL
  # \N -> NL
  # \, -> ,
  def Vpim.decode_text(v) # :nodoc:
    v.gsub(/\\[nN]/, "\n").gsub(/\\,/, ",").gsub(/\\\\/) { |m| "\\" }
  end


  # Unfold the lines in +card+, then return an array of one Field object per
  # line.
  def Vpim.decode(card) #:nodoc:
      content = Vpim.unfold(card).collect { |line| DirectoryInfo::Field.decode(line) }
  end


  # Expand an array of fields into its syntactic entities. Each entity is a sequence
  # of fields where the sequences is delimited by a BEGIN/END field. Since
  # BEGIN/END delimited entities can be nested, we build a tree. Each entry in
  # the array is either a Field or an array of entries (where each entry is
  # either a Field, or an array of entries...).
  def Vpim.expand(src) #:nodoc:
    # output array to expand the src to
    dst = []
    # stack used to track our nesting level, as we see begin/end we start a
    # new/finish the current entity, and push/pop that entity from the stack
    current = [ dst ]

    for f in src
      if f.name? 'begin'
        e = [ f ]

        current.last.push(e)
        current.push(e)

      elsif f.name? 'end'
        current.last.push(f)

        unless current.last.first.value? current.last.last.value
          raise "BEGIN/END mismatch (#{current.last.first.value} != #{current.last.last.value})"
        end

        current.pop

      else
        current.last.push(f)
      end
    end

    dst
  end

  # Split an array into an array of all the fields at the outer level, and
  # an array of all the inner arrays of fields. Return the array [outer,
  # inner].
  def Vpim.outer_inner(fields) #:nodoc:
    # seperate into the outer-level fields, and the arrays of component
    # fields
    outer = []
    inner = []
    fields.each do |line|
      case line
      when Array; inner << line
      else;       outer << line
      end
    end
    return outer, inner
  end

end

