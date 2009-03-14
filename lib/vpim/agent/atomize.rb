=begin
  Copyright (C) 2009 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require "atom"

module Vpim
  module Agent

    module Atomize
      MIME = "application/atom+xml"

      # +ical+, an icalendar, or at least a Repo calendar's subset of an Icalendar
      # +feeduri+, the atom xml should know the URI of where the feed is available from.
      # +caluri+, optionally, the URI of the calendar its converted from.
      #
      # TODO - and the URI of an alternative/html representation of this feed?
      def self.calendar(ical, feeduri, caluri = nil, calname = nil)
        mime = MIME

        feeduri = feeduri.to_str
        caluri = caluri
        calname = (calname or caluri or "Unknown").to_str

        f = Atom::Feed.new
        # Mandatory attributes:
        # For ID, we should use http://.../ics/atom?....., or just the URL of the ics?
        #   I think it can be a full URI... or maybe a sha-1 of our full URI?
        # or like gmail, no id for feed,
        #   <id>tag:gmail.google.com,2004:1295062805013769502</id>
        #
        f.id = feeduri
        f.title = calname
        f.updated = Time.now
        f.authors << Atom::Person.new(:name => (caluri or calname))
        f.generator = Atom::Generator.new do |g|
          g.name = Vpim::PRODID
          g.uri = "http://vpim.rubyforge.org"
          g.version = Vpim::VERSION
        end

        f.links << Atom::Link.new do |l|
          l.href = feeduri
          l.type = mime
          l.rel  = :self
        end

        if caluri
          # This is maybe better described as :via, but with :alternate being
          # an html view of this feed.
          #
          # TODO should I change the scheme to be webcal?
          # TODO should I extend URI to support webcal?
          f.links << Atom::Link.new do |l|
            l.href = caluri
            l.type = "text/calendar"
            l.rel  = :alternate
          end
        end

        # .icon = uri to the vAgent icon
        entry_id = 0
        ical.events do |ve|
          # TODO - infinite?
          ve.occurrences do |t|
            f.entries << Atom::Entry.new do |e|
              # iCalendar -> atom
              # -----------------
              # summary -> title
              # description -> text/content
              # uid -> id
              # created -> published?
              # organizer -> author?
              # contact -> author?
              # last-mod -> semantically, this is updated, but atom doesn't
              #   have the notion that an entry has a relationship to a time,
              #   other than the time the entry itself was published, and when
              #   the entry gets updated. We'll abuse updated for the event's time.
              # categories -> where do "tags" go in atom, if anywhere?
              # attachment -> into a link?
              e.title = ve.summary if ve.summary
              e.content = Atom::Content::Text.new(ve.description) if ve.description
              e.updated = t

              # Use "tag:", as defined by RFC4151, and use event UID if possible. Otherwise,
              # construct something. Maybe I should mix something in to make it unique for
              # each time a feed is generated for the calendar?
              entry_id += 1
              tag = ve.uid || "#{entry_id}@#{feeduri}"
              e.id = "tag:vpim.rubyforge.org,2009:#{tag}"
            end
          end
        end
        return f
      end
    end # Atomize

  end # Agent
end # Vpim

