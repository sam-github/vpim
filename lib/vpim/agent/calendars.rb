=begin
  Copyright (C) 2008 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require "cgi"
require "uri"

require "vpim/repo"
require "vpim/agent/atomize"

module Vpim
  module Agent
    # On failure, raise this with an error message. text/plain for now,
    # text/html later. Will convert to a 404 and a message.
    class NotFound < Exception
      def initialize(name, path)
        super %{Resource "#{name}" under "#{path.prefix}" was not found!}
      end
    end

    class Path
      def self.split_path(path)
        begin
          path = path.to_ary
        rescue NameError
          path = path.split("/")
        end
        path.map{|w| CGI.unescape(w)}
      end

      # URI is the uri being queried, base is where this path is mounted under?
      def initialize(uri, base = "")
        @uri  = URI.parse(uri.to_s)
        #pp [uri, base, @uri]
       if @uri.path.size == 0
         @uri.path = "/"
       end
        @path = Path.split_path(@uri.path)
        @base = base.to_str
        @mark = 0

        @base.split.size.times{ shift }
      end

      def uri
        @uri.to_s
      end

      def to_path
        self
      end

      # TODO - call this #next
      def shift
        if @path[@mark]
          @path[@mark += 1]
        end
      end

      def append(name, scheme = nil)
        uri = @uri.dup
        uri.path += "/" + CGI.escape(name)
        if scheme
          uri.scheme = scheme
        end
        uri
      end

      def prefix(len = nil)
        len ||= @mark
        @path[0, len].map{|p| CGI.escape(p)}.join("/") + "/"
      end

    end

    module Form
      ATOM  = Atomize::MIME
      HTML  = "text/html"
      ICS   = "text/calendar"
      PLAIN = "text/plain"
      VCF   = "text/directory"
    end

    # Return an HTML description of a list of resources accessible under this
    # path.
    class ResourceList
      def initialize(description, items)
        @description = description
        @items = items
      end

      def get(path)
        return <<__, Form::HTML
<html><body>
#{@description}
<ul>
  #{
    @items.map do |name,description,scheme|
      "<li><a href=\"#{path.append(name,scheme)}\">#{description || name}</a></li>\n"
    end
  }
</ul>
</body></html>
__
      end
    end

    # Return calendar information based on RESTful (lovein' the jargon...)
    # paths. Input is a Vpim::Repo.
    #
    #   .../coding/month/atom
    #   .../coding/events/month/ics              <- next month?
    #   .../coding/events/month/2008-04/ics      <- a specified month?
    #   .../coding/week/atom
    #   .../year/atom
    class Calendars
      def initialize(repo)
        @repo = repo
      end

      class Calendar
        def initialize(cal)
          @cal = cal
          @list = ResourceList.new(
              "Calendar #{@cal.name.inspect}:",
              [
                ["calendar", "download"],
                ["calendar", "subscription", "webcal"],
                ["atom",     "syndication"],
              ]
            )
        end

        def get(path)
          form = path.shift

          # TODO should redirect to an object, so that extra paths can be
          # handled more gracefully.
          case form
          when nil
            return @list.get(path)
          when "calendar"
            return @cal.encode, Form::ICS
          when "atom"
            return Atomize.calendar(@cal, path.uri, nil, @cal.name).to_xml, Form::ATOM
          else
            raise NotFound.new(form, path)
          end
        end
      end

      # Get object at this path. Return value is a tuple of data and mime content type.
      def get(path)
        case name = path.to_path.shift
        when nil
          list = ResourceList.new("Calendars:", @repo.map{|c| c.name})
          return list.get(path)
        else
          if cal = @repo.find{|c| c.name == name}
            return Calendar.new(cal).get(path)
          else
            raise NotFound.new(name, path)
          end
        end
      end
    end
  end
end

