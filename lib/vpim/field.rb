=begin
  Copyright (C) 2006 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'vpim/rfc2425'
require 'vpim/vpim'
require 'date'

module Vpim

  class DirectoryInfo

    # A field in a directory info object.
    class Field
      private_class_method :new

      def Field.create_array(fields)
        case fields
          when Hash
            fields.map do |name,value|
              DirectoryInfo::Field.create( name, value )
            end
          else
            fields.to_ary
        end
      end

      # Encode a field.
      def Field.encode0(group, name, params={}, value='') # :nodoc:
        line = ""

        # A reminder of the line format:
        #   [<group>.]<name>;<pname>=<pvalue>,<pvalue>:<value>

        if group
          line << group << '.'
        end
        
        line << name

        params.each do |pname, pvalues|

          unless pvalues.respond_to? :to_ary
            pvalues = [ pvalues ]
          end

          line << ';' << pname << '='

          sep = "" # set to ',' after one pvalue has been appended

          pvalues.each do |pvalue|
            # check if we need to do any encoding
            if pname.downcase == 'encoding' && pvalue == :b64
              pvalue = 'b' # the RFC definition of the base64 param value
              value = [ value.to_str ].pack('m').gsub("\n", '')
            end

            line << sep << pvalue
            sep =",";
          end
        end

        line << ':'

        line << Field.value_str(value)

        line
      end

      def Field.value_str(value) # :nodoc:
        line = ''
        case value
          when Date
            line << Vpim.encode_date(value)

          when Time #, DateTime
            line << Vpim.encode_date_time(value)

          when Array
            line << value.map { |v| Field.value_str(v) }.join(';')

          when Symbol
            line << value

          else
            line << value.to_str
        end
        line
      end

      # Decode a field.
      def Field.decode0(atline) # :nodoc:
        unless atline =~ %r{#{Bnf::LINE}}i
          raise Vpim::InvalidEncodingError, atline
        end

        atgroup = $1
        atname = $2
        paramslist = $3
        atvalue = $~[-1]

        if atgroup.length > 0
          atgroup.chomp!('.')
        else
          atgroup = nil
        end

        atparams = {}

        # Collect the params, if any.
        if paramslist.size > 1

          # v3.0 and v2.1 params
          paramslist.scan( %r{#{Bnf::PARAM}}i ) do

            # param names are case-insensitive, and multi-valued
            name = $1.downcase
            params = $3

            # v2.1 params have no '=' sign, figure out what kind of param it
            # is (either its a known encoding, or we treat it as a 'type'
            # param).
           
            if $2 == ""
              params = $1
              case $1
                when /quoted-printable/i
                  name = 'encoding'

                when /base64/i
                  name = 'encoding'

                else
                  name = 'type'
              end
            end

            # TODO - In ruby1.8 I can give an initial value to the atparams
            # hash values instead of this.
            unless atparams.key? name
              atparams[name] = []
            end

            params.scan( %r{#{Bnf::PVALUE}} ) do
              atparams[name] << ($1 || $2) # Used to do this, want to stop! .downcase
            end
          end
        end

        [ atgroup, atname, atparams, atvalue ]
      end

      def initialize(line) # :nodoc:
        @line = line.to_str
        @group, @name, @params, @value = Field.decode0(@line)
        self
      end

      # Create a field by decoding +line+, a String which must already be
      # unfolded. Decoded fields are frozen, but see #copy().
      def Field.decode(line)
        new(line).freeze
      end

      # Create a field with name +name+ (a String), value +value+ (see below),
      # and optional parameters, +params+. +params+ is a hash of the parameter
      # name (a String) to either a single string or symbol, or an array of
      # strings and symbols (parameters can be multi-valued).
      #
      # If 'encoding' => :b64 is specified as a parameter, the value will be
      # base-64 encoded. If it's already base-64 encoded, then use String
      # values ('encoding' => 'b'), and no further encoding will be done by
      # this routine.
      #
      # Currently handled value types are:
      # - Time, encoded as a date-time value
      # - Date, encoded as a date value
      # - String, encoded directly
      # - Array of String, concatentated with ';' between them.
      #
      # TODO - need a way to encode String values as TEXT, at least optionally,
      # so as to escape special chars, etc.
      def Field.create(name, value="", params={})
        line = Field.encode0(nil, name, params, value)

        begin
          new(line)
        rescue Vpim::InvalidEncodingError => e
          raise ArgumentError, e.to_s
        end
      end

      # Create a copy of Field. If the original Field was frozen, this one
      # won't be.
      def copy
        Marshal.load(Marshal.dump(self))
      end

      # The String encoding of the Field. The String will be wrapped to a
      # maximum line width of +width+, where +0+ means no wrapping, and nil is
      # to accept the default wrapping (75, recommended by RFC2425).
      #
      # Note: Apple's Address Book 3.0.3 neither understands to unwrap lines
      # when it imports vCards (it treats them as raw new-line characters), nor
      # wraps long lines on export. On import, this is mostly a cosmetic
      # problem, but wrapping can be disabled by setting width to +0+, if
      # desired. On export, its a more serious bug, since Address Book wil
      # encode the entire Note: section as a single, very long, line.
      def encode(width=nil)
        width = 75 unless width
        l = @line
        # Wrap to width, unless width is zero.
        if width > 0
          l = l.gsub(/.{#{width},#{width}}/) { |m| m + "\n " }
        end
        # Make sure it's terminated with no more than a single NL.
        l.gsub(/\s*\z/, '') + "\n"
      end

      alias to_s encode

      # The name.
      def name
        @name
      end

      # The group, if present, or nil if not present.
      def group
        @group
      end

      # An Array of all the param names.
      def params
        @params.keys
      end

      # The Array of all values of the param +name+, or nil if there is no
      # such param.
      #
      # TODO - this doesn't return [] if the param isn't found, because then
      # you can't distinguish between a param with no values, and a param that
      # isn't defined. But maybe it isn't useful? You can always do
      # params.include?(a_name) if you want to know if it exists. Maybe this
      # should take a block specifying the default value, even?
      def param(name)
        v = @params[name.downcase]
        if v
          v = v.collect do |p|
            p.downcase.freeze
          end
          v.freeze
        end
        v
      end

      alias [] param

      # Yield once for each param, +name+ is the parameter name, +value+ is an
      # array of the parameter values.
      def each_param(&block) #:yield: name, value
        if @params
          @params.each(&block)
        end
      end

      # The decoded value.
      #
      # The encoding specified by the #encoding, if any, is stripped.
      #
      # Note: Both the RFC 2425 encoding param ("b", meaning base-64) and the
      # vCard 2.1 encoding params ("base64", "quoted-printable", "8bit", and
      # "7bit") are supported.
      def value
        case encoding
          when nil, '8bit', '7bit' then @value

          # Hack - if the base64 lines started with 2 SPC chars, which is invalid,
          # there will be extra spaces in @value. Since no SPC chars show up in
          # b64 encodings, they can be safely stripped out before unpacking.
          when 'b', 'base64'       then @value.gsub(' ', '').unpack('m*').first

          when 'quoted-printable'  then @value.unpack('M*').first

          else raise Vpim::InvalidEncodingError, "unrecognized encoding (#{encoding})"
        end
      end

      # Is the #name of this Field +name+? Names are case insensitive.
      def name?(name)
        name.to_s.downcase == @name.downcase
      end

      # Is the #group of this field +group+? Group names are case insensitive.
      # A +group+ of nil matches if the field has no group.
      def group?(group)
        g1 = @group ? @group.downcase : nil
        g2 =  group ?  group.downcase : nil
        g1 == g2
      end

      # Is the value of this field of type +kind+? RFC2425 allows the type of
      # a fields value to be encoded in the VALUE parameter. Don't rely on its
      # presence, they aren't required, and usually aren't bothered with. In
      # cases where the kind of value might vary (an iCalendar DTSTART can be
      # either a date or a date-time, for example), you are more likely to see
      # the kind of value specified explicitly.
      #
      # The value types defined by RFC 2425 are:
      # - uri:
      # - text:
      # - date: a list of 1 or more dates
      # - time: a list of 1 or more times
      # - date-time: a list of 1 or more date-times
      # - integer:
      # - boolean:
      # - float:
      def kind?(kind)
        kind.downcase == self.kind
      end

      # Is one of the values of the TYPE parameter of this field +type+? The
      # type parameter values are case insensitive. False if there is no TYPE
      # parameter.
      #
      # TYPE parameters are used for general categories, such as
      # distinguishing between an email address used at home or at work.
      def type?(type)
        types = param('type')

        if types
          types = types.include?(type.to_str.downcase)
        end
      end

      # Is this field marked as preferred? A vCard field is preferred if
      # #type?('pref'). This method is not necessarily meaningful for
      # non-vCard profiles.
      def pref?
        type?('pref')
      end

      # Is the value of this field +value+? The check is case insensitive.
      def value?(value)
         @value && @value.downcase == value.downcase
      end

      # The value of the ENCODING parameter, if present, or nil if not
      # present.
      def encoding
        e = param("encoding")

        if e
          if e.length > 1
            raise Vpim::InvalidEncodingError, "multi-valued param 'encoding' (#{e})"
          end
          e = e.first
        end
        e
      end

      # The type of the value, as specified by the VALUE parameter, nil if
      # unspecified.
      def kind
        v = param('value')
        if v
          if v.size > 1
            raise InvalidEncodingError, "multi-valued param 'value' (#{values})"
          end
          v = v.first
        end
        v
      end

      # The value as an array of Time objects (all times and dates in
      # RFC2425 are lists, even where it might not make sense, such as a
      # birthday). The time will be UTC if marked as so (with a timezone of
      # "Z"), and in localtime otherwise.
      #
      # TODO: support timezone offsets
      #
      # TODO - if year is before 1970, this won't work... but some people
      # are generating calendars saying Canada Day started in 1753!
      # That's just wrong! So, what to do? I add a message
      # saying what the year is that breaks, so they at least know that
      # its ridiculous! I think I need my own DateTime variant.
      def to_time
        begin
          Vpim.decode_date_time_list(value).collect do |d|
            # We get [ year, month, day, hour, min, sec, usec, tz ]
            begin
              if(d.pop == "Z")
                Time.gm(*d)
              else
                Time.local(*d)
              end
            rescue ArgumentError => e
              raise Vpim::InvalidEncodingError, "Time.gm(#{d.join(', ')}) failed with #{e.message}"
            end
          end
        rescue Vpim::InvalidEncodingError
          Vpim.decode_date_list(value).collect do |d|
            # We get [ year, month, day ]
            begin
              Time.gm(*d)
            rescue ArgumentError => e
              raise Vpim::InvalidEncodingError, "Time.gm(#{d.join(', ')}) failed with #{e.message}"
            end
          end
        end
      end

      # The value as an array of Date objects (all times and dates in
      # RFC2425 are lists, even where it might not make sense, such as a
      # birthday).
      #
      # The field value may be a list of either DATE or DATE-TIME values,
      # decoding is tried first as a DATE-TIME, then as a DATE, if neither
      # works an InvalidEncodingError will be raised.
      def to_date
        begin
          Vpim.decode_date_time_list(value).collect do |d|
            # We get [ year, month, day, hour, min, sec, usec, tz ]
            Date.new(d[0], d[1], d[2])
          end
        rescue Vpim::InvalidEncodingError
          Vpim.decode_date_list(value).collect do |d|
            # We get [ year, month, day ]
            Date.new(*d)
          end
        end
      end

      # The value as text. Text can have escaped newlines, commas, and escape
      # characters, this method will strip them, if present.
      #
      # In theory, #value could also do this, but it would need to know that
      # the value is of type 'text', and often for text values the 'type'
      # parameter is not present, so knowledge of the expected type of the
      # field is required from the decoder.
      def to_text
        Vpim.decode_text(value)
      end

      # The undecoded value, see +value+.
      def value_raw
        @value
      end

      def inspect # :nodoc:
        @line
      end

      # TODO def pretty_print() ...

      # Set the group of this field to +group+.
      def group=(group)
        mutate(group, @name, @params, @value)
        group
      end

      # Set the value of this field to +value+.  Valid values are as in
      # Field.create().
      def value=(value)
        mutate(@group, @name, @params, value)
        value
      end

      # Convert +value+ to text, then assign.
      #
      # TODO - unimplemented
      def text=(text)
      end

      # Set a the param +param+'s value to +pvalue+. Valid values are as in
      # Field.create().
      def []=(param,pvalue)
        unless pvalue.respond_to?(:to_ary)
          pvalue = [ pvalue ]
        end

        h = @params.dup

        h[param.downcase] = pvalue

        mutate(@group, @name, h, @value)
        pvalue
      end

      def mutate(g, n, p, v) #:nodoc:
        line = Field.encode0(g, n, p, v)

        begin
          @group, @name, @params, @value = Field.decode0(line)
          @line = line
        rescue Vpim::InvalidEncodingError => e
          raise ArgumentError, e.to_s
        end
        self
      end

      private :mutate
    end
  end
end

