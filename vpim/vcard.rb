=begin
  $Id: vcard.rb,v 1.13 2004/12/05 03:16:33 sam Exp $

  Copyright (C) 2005 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'vpim/dirinfo'
require 'vpim/vpim'

module Vpim
  # A vCard, a specialization of a directory info object.
  #
  # The vCard format is specified by:
  # - RFC2426: vCard MIME Directory Profile (vCard 3.0)
  # - RFC2425: A MIME Content-Type for Directory Information
  #
  # This implements vCard 3.0, but it is also capable of decoding vCard 2.1.
  #
  # For information about:
  # - link:rfc2426.txt: vCard MIME Directory Profile (vCard 3.0)
  # - link:rfc2425.txt: A MIME Content-Type for Directory Information
  # - http://www.imc.org/pdi/pdiproddev.html: vCard 2.1 Specifications
  #
  # vCards are usually transmitted in files with <code>.vcf</code>
  # extensions.
  #
  # TODO - an open question is what exactly "vcard 2.1" support means. While I
  # decode vCard 2.1 correctly, I don't encode it. Should I implement a
  # transcoder, to vCards can be decoded from either version, and then written
  # to either version? Maybe an option to Field#encode()?
  #
  # TODO - there are very few methods that Vcard has that DirectoryInfo
  # doesn't. I could probably just do away with it entirely, but I suspect
  # that there are methods that could be usefully added to Vcard, perhaps to
  # get the email addresses, or the name, or perhaps to set fields, like
  # email=. What would be useful?
  #
  # = Example
  #
  # Here's an example of encoding a simple vCard using the low-level API:
  #
  #   card = Vpim::Vcard.create
  #   card << Vpim::DirectoryInfo::Field.create('email', user.name@example.com, 'type' => "internet" )
  #   card << Vpim::DirectoryInfo::Field.create('url', "http://www.example.com/user" )
  #   card << Vpim::DirectoryInfo::Field.create('fn', "User Name" )
  #   puts card.to_s
  #
  # New! Use the Vpim::Maker::Vcard to make vCards!
  class Vcard < DirectoryInfo

    private_class_method :new

    # Create a vCard 3.0 object with the minimum required fields, plus any
    # +fields+ you want in the card (they can also be added later).
    def Vcard.create(fields = [] )
      fields.unshift Field.create('VERSION', "3.0")
      super(fields, 'VCARD')
    end

    # Decode a collection of vCards into an array of Vcard objects.
    #
    # +card+ can be either a String or an IO object.
    #
    # Since vCards are self-delimited (by a BEGIN:vCard and an END:vCard),
    # multiple vCards can be concatenated into a single directory info object.
    # They may or may not be related. For example, AddressBook.app (the OS X
    # contact manager) will export multiple selected cards in this format.
    #
    # The card data must be UTF-8 (ASCII is valid UTF-8) or UCS-2 (2 byte
    # Unicode). All valid vCards must begin with "BEGIN:VCARD", and the UCS-2
    # encoding of 'B' is a the nul character (0x00) followed by the ASCII
    # value of 'B', so the input is considered to be UCS-2 if the first
    # character in the string is nul, and converted to UTF-8.
    #
    # If you know that you have only one vCard, then you can decode that
    # single vCard by doing something like:
    #
    #   vcard = Vcard.decode(card_data).first
    def Vcard.decode(card)
      if card.respond_to? :to_str
        string = card.to_str
      elsif card.kind_of? IO
        string = card.read(nil)
      else
        raise ArgumentError, "Vcard.decode cannot be called with a #{card.type}"
      end

      # The card representation can be either UTF-8, or UCS-2. If its
      # UCS-2, then the first byte will be 0, so check for this, and convert
      # if necessary.
      #
      # We know it's 0, because the first character in a vCard must be the 'B'
      # of "BEGIN:VCARD", and in UCS-2 all ascii are encoded as a 0 byte
      # followed by the ASCII byte, UNICODE is great.
      if string[0] == 0
        string = string.unpack('n*').pack('U*')
      end

      entities = Vpim.expand(Vpim.decode(string))

      # Since all vCards must have a begin/end, the top-level should consist
      # entirely of entities/arrays, even if its a single vCard.
      if entities.detect { |e| ! e.kind_of? Array }
        raise "Not a valid vCard"
      end

      vcards = []

      for e in entities
        vcards.push(new(e.flatten, 'VCARD'))
      end

      vcards
    end

    # The vCard version multiplied by 10 as an Integer.  If no VERSION field
    # is present (which is non-conformant), nil is returned.  For example, a
    # version 2.1 vCard would have a version of 21, and a version 3.0 vCard
    # would have a version of 30.
    def version
      v = self["version"]
      unless v
        raise Vpim::InvalidEncodingError, 'Invalid vCard - it has no version field!'
      end
      v = v.to_f * 10
      v = v.to_i
    end

    # The value of the field named +name+, optionally limited to fields of
    # type +type+. If no match is found, nil is returned, if multiple matches
    # are found, the first match to have one of its type values be 'pref'
    # (preferred) is returned, otherwise the first match is returned.
    def [](name, type=nil)
      fields = enum_by_name(name).find_all { |f| type == nil || f.type?(type) }

      # limit to preferred, if possible
      pref = fields.find_all { |f| f.pref? }

      if(pref.first)
        fields = pref
      end

      fields.first ? fields.first.value : nil
    end

    # The nickname or nil if there is none.
    def nickname
      nn = self['nickname']
      if nn
        nn = nn.sub(/^\s+/, '')
        nn = nn.sub(/\s+$/, '')
        nn = nil if nn == ''
      end
      nn
    end


    # Returns the birthday as a Date on success, nil if there was no birthday
    # field, and raises an error if the birthday field could not be expressed
    # as a recurring event.
    #
    # Also, I have a lot of vCards with dates that look like:
    #   678-09-23
    # The 678 is garbage, but 09-23 is really the birthday. This substitutes the
    # current year for the 3 digit year, and then converts to a Date.
    def birthday
      bday = self.field('BDAY')

      return nil unless bday

      begin
        date = bday.to_date.first

      rescue Vpim::InvalidEncodingError
        if bday.value =~ /(\d+)-(\d+)-(\d+)/
          y = $1.to_i
          m = $2.to_i
          d = $3.to_i
          if(y < 1900)
            y = Time.now.year
          end
          date = Date.new(y, m, d)
        else
          raise
        end
      end

      date
    end

  end
end

