=begin
  Copyright (C) 2009 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

# The only atom-generating library I could find on rubyforge has a dependency
# on libxml2, and only a newer libxml version than OS 10.5 has... so fake
# out the new stuff, it doesn't seem to be needed for generation.
module XML
  class Reader
  end
end

require "atom"

module Vpim
  module Agent

    class Atomize
      MIME = "application/atom+xml"

      def initialize(cal)
        @cal = cal
        @id = 0
      end

      def id
        @id += 1
        "http://example.com/#{@id}"
      end

      def get(path=nil)
        f = Atom::Feed.new
        f.title = @cal.name
        f.updated = Time.now
        # Should .id be the URL to the feed?
        f.id = id
        f.authors << Atom::Person.new(:name => "vAgent")
        # Should be a link:
        # .links << Atom::Link()
        # .icon = ?
        @cal.events do |ve|
          ve.occurrences do |t|
            f.entries << Atom::Entry.new do |e|
              e.title = ve.summary
              e.updated = t
              e.content = Atom::Content::Html.new ve.summary
              # .summary = Don't need when there is content.
              # Maybe I can use the UUID from the ventry for the ID?
              e.id = id
            end
          end
        end
        return f.to_xml
      end
    end

  end # Agent
end # Vpim

