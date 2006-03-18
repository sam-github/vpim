=begin
  Copyright (C) 2006 Sam Roberts

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
  # transcoder, so vCards can be decoded from either version, and then written
  # to either version? Maybe an option to Field#encode()?
  #
  # TODO - there are very few methods that Vcard has that DirectoryInfo
  # doesn't. I could probably just do away with it entirely, but I suspect
  # that there are methods that could be usefully added to Vcard, perhaps to
  # get the email addresses, or the name, or perhaps to set fields, like
  # email=. What would be useful?
  #
  # = Examples
  #
  # - link:ex_mkvcard.txt: example of creating a vCard
  # - link:ex_cpvcard.txt: example of copying and them modifying a vCard
  # - link:ex_mkv21vcard.txt: example of creating version 2.1 vCard
  # - link:mutt-aliases-to-vcf.txt: convert a mutt aliases file to vCards
  # - link:ex_get_vcard_photo.txt: pull photo data from a vCard
  # - link:ab-query.txt: query the OS X Address Book to find vCards
  # - link:vcf-to-mutt.txt: query vCards for matches, output in formats useful
  #   with Mutt (see link:README.mutt for details)
  # - link:tabbed-file-to-vcf.txt: convert a tab-delimited file to vCards, a
  #   (small but) complete application contributed by Dane G. Avilla, thanks!
  # - link:vcf-to-ics.txt: example of how to create calendars of birthdays from vCards
  # - link:vcf-dump.txt: utility for dumping contents of .vcf files
  #
  # Here's an example of encoding a simple vCard using the low-level API:
  #
  #   card = Vpim::Vcard.create
  #   card << Vpim::DirectoryInfo::Field.create('EMAIL', 'user.name@example.com', 'TYPE' => 'INTERNET' )
  #   card << Vpim::DirectoryInfo::Field.create('URL', 'http://www.example.com/user' )
  #   card << Vpim::DirectoryInfo::Field.create('FN', 'User Name' )
  #   puts card.to_s
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
    # Input data will be converted from unicode if it is detected. The heuristic
    # is based on the first bytes in the string:
    # - 0xEF 0xBB 0xBF: UTF-8 with a BOM, the BOM is stripped
    # - 0xFE 0xFF: UTF-16 with a BOM (big-endian), the BOM is stripped and string
    #   is converted to UTF-8
    # - 0xFF 0xFE: UTF-16 with a BOM (little-endian), the BOM is stripped and string
    #   is converted to UTF-8
    # - 0x00 'B' or 0x00 'b': UTF-16 (big-endian), the string is converted to UTF-8
    # - 'B' 0x00 or 'b' 0x00: UTF-16 (little-endian), the string is converted to UTF-8
    #
    # If you know that you have only one vCard, then you can decode that
    # single vCard by doing something like:
    #
    #   vcard = Vcard.decode(card_data).first
    #
    # Note: Should the import encoding be remembered, so that it can be reencoded in
    # the same format?
    def Vcard.decode(card)
      if card.respond_to? :to_str
        string = card.to_str
      elsif card.kind_of? IO
        string = card.read(nil)
      else
        raise ArgumentError, "Vcard.decode cannot be called with a #{card.type}"
      end

      case string
        when /^\xEF\xBB\xBF/
          string = string.sub("\xEF\xBB\xBF", '')
        when /^\xFE\xFF/
          arr = string.unpack('n*')
          arr.shift
          string = arr.pack('U*')
        when /^\xFF\xFE/
          arr = string.unpack('v*')
          arr.shift
          string = arr.pack('U*')
        when /^\x00\x62/i
          string = string.unpack('n*').pack('U*')
        when /^\x62\x00/i
          string = string.unpack('v*').pack('U*')
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
    # are found, the first match to have one of its type values be 'PREF'
    # (preferred) is returned, otherwise the first match is returned.
    def [](name, type=nil)
      fields = enum_by_name(name).find_all { |f| type == nil || f.type?(type) }

      valued = fields.select { |f| f.value != '' }
      if valued.first
        fields = valued
      end

      # limit to preferred, if possible
      pref = fields.select { |f| f.pref? }

      if pref.first
        fields = pref
      end

      fields.first ? fields.first.value : nil
    end

    # The name from a vCard, including all the components of the N: and FN:
    # fields.

    class Name
      # family name from N:
      attr_reader :family
      # given name from N:
      attr_reader :given
      # additional names from N:
      attr_reader :additional
      # such as "Ms." or "Dr.", from N:
      attr_reader :prefix
      # such as "BFA", from N:
      attr_reader :suffix
      # all the components of N: formtted as "#{prefix} #{given} #{additional} #{family}, #{suffix}"
      attr_reader :formatted
      # full name, the FN: field, a formatted version of the N: field, probably
      # in a form more align with the cultural conventions of the vCard owner
      # than +formatted+ is
      attr_reader :fullname

      def initialize(n, fn) #:nodoc:
        n = Vpim.decode_list(n, ';') do |item|
          item.strip
        end

        @family     = n[0] || ""
        @given      = n[1] || ""
        @additional = n[2] || ""
        @prefix     = n[3] || ""
        @suffix     = n[4] || ""
        @formatted = [ @prefix, @given, @additional, @family ].map{|i| i == '' ? nil : i}.compact.join(' ')
        if @suffix != ''
          @formatted << ', ' << @suffix
        end

        # FIXME - make calls to #fullname fail if fn is nil
        @fullname = fn
      end

    end

    # Returns the +name+ fields, N: and FN:, as a Name.
    def name
      unless instance_variables.include? '@name'
        @name = Name.new(self['N'], self['FN'])
      end
      @name
    end

    # Deprecated.
    def nickname #:nodoc:
      nn = self['NICKNAME']
      if nn && nn == ''
        nn = nil
      end
      nn
    end

    # All the nicknames, [] if there are none.
    def nicknames
      enum_by_name('NICKNAME').select{|f| f.value != ''}.collect{|f| f.value}
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

