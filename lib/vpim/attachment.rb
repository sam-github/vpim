=begin
  Copyright (C) 2006 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'vpim/icalendar'

module Vpim

  ## FIXME - do this like Vcard does

  class Attachment
    # A String, if attachment is a URI, or nil.
    attr_reader :uri
    # A String, the value if attachment is inline, or nil.
    attr_reader :binary
    # A String, a MIME format string ("text/plain", "image/jpeg", ...), or an
    # iana registered format (whatever that is), or nil.
    attr_reader :format

    # The value as a StringIO if the value is inline, or an IO if
    # the value is a URI (see open-uri for more details).
    def value
      if binary
        require 'stringio'
        StringIO.new(binary)
      else
        require 'open-uri'
        open(uri)
      end
    end

    def initialize(uri, binary, format) #:nodoc:
      @uri = uri
      @binary = binary
      @format = format
    end

    def self.field(f, default_value_type, format_parameter) #:nodoc:
      value = f.value

      # TODO - make Field#value support value= statements.
      value_type = f['VALUE']
      if value_type
        value_type = value_type.first.upcase
      else
        value_type = default_value_type
      end

      uri = nil
      binary = nil

      case value_type
      when 'BINARY'
        binary = value
      when 'URI'
        uri = value
      else
        raise Vpim::UnsupportedError, "attachment value of #{value_type}"
      end

      format = f[format_parameter]
      if format
        format = format.first
      end

      new(uri, binary, format)
    end

  end
end

