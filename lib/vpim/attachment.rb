module Vpim
  class Icalendar

    class Attachment
      # A String, the URI for a URI attachment, or nil.
      attr_reader :uri
      # A String, the value of an inline attachment, or nil.
      attr_reader :binary
      # A String, a MIME format string ("text/plain", "image/jpeg", ...), or nil.
      attr_reader :format

      def initialize(uri, binary, format) #:nodoc:
        @uri = uri
        @binary = binary
        @format = format
      end

      # The value as a StringIO if the value is inline binary, or the IO
      # returned by open after requiring the open-uri library.
      def value
        if binary
          require 'stringio'
          StringIO.new(binary)
        else
          require 'open-uri'
          open(uri)
        end
      end

    end

  end
end

