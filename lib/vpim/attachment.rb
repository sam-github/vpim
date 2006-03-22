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

      def inspect
        "#<Icalendar::Attachment uri=#{uri.inspect} binary=#{binary.inspect} format=#{format.inspect}>"
      end

    end

  end
end

