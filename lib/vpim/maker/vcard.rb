=begin
  Copyright (C) 2006 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'vpim/vcard'

module Vpim
  module Maker #:nodoc:
    # A class to make and make changes to vCards.
    #
    # It can be used to create completely new vCards using Vcard#make2.
    #
    # Its is also yielded from Vpim::Vcard#make, in which case it allows a kind
    # of transactional approach to changing vCards, so their values can be
    # validated after any changes have been made.
    #
    # Examples:
    # - link:ex_mkvcard.txt: example of creating a vCard
    # - link:ex_cpvcard.txt: example of copying and them modifying a vCard
    # - link:ex_mkv21vcard.txt: example of creating version 2.1 vCard
    # - link:ex_mkyourown.txt: example of adding support for new fields to Maker::Vcard
    class Vcard
      # Make a vCard.
      #
      # Yields +maker+, a Vpim::Maker::Vcard which allows fields to be added to
      # +card+, and returns +card+, a Vpim::Vcard.
      #
      # If +card+ is nil or not provided a new Vpim::Vcard is created and the
      # fields are added to it.
      #
      # Defaults:
      # - vCards must have both an N and an FN field, #make2 will fail if there
      #   is no N field in the +card+ when your block is finished adding fields.
      # - If there is an N field, but no FN field, FN will be set from the
      #   information in N, see Vcard::Name#preformatted for more information.
      # - vCards must have a VERSION field. If one does not exist when your block is
      #   is finished it will be set to 3.0.
      def Vcard.make2(card = Vpim::Vcard.create, &block) # :yields: maker
        new(nil, card).make(&block)
      end

      # Deprecated, use #make2.
      #
      # If set, the FN field will be set to +full_name+. Otherwise, FN will
      # be set from the values in #name.
      def Vcard.make(full_name = nil, &block) # :yields: maker
        new(full_name, Vpim::Vcard.create).make(&block)
      end

      def make # :nodoc:
        yield self
        unless @card['N']
          raise Unencodeable, 'N field is mandatory'
        end
        fn = @card.field('FN')
        if fn && fn.value.strip.length == 0
          @card.delete(fn)
          fn = nil
        end
        unless fn
          @card << Vpim::DirectoryInfo::Field.create('FN', Vpim::Vcard::Name.new(@card['N'], '').formatted)
        end
        unless @card['VERSION']
          @card << Vpim::DirectoryInfo::Field.create('VERSION', "3.0")
        end
        @card
      end

      private

      def initialize(full_name, card) # :nodoc:
        @card = card || Vpim::Vcard::create
        if full_name
          @card << Vpim::DirectoryInfo::Field.create('FN', full_name.strip )
        end
      end

      public

      #     def add_name # :yield: n
      #       # FIXME: Each attribute can currently only have a single String value.
      #       # FIXME: Need to escape specials in the String.
      #       x = Struct.new(:family, :given, :additional, :prefix, :suffix).new
      #       yield x
      #       @card << Vpim::DirectoryInfo::Field.create(
      #         'N',
      #         x.map { |s| s ? s.to_str : '' }
      #         )
      #       self
      #     end
      # Set with #name now.
      # Use m.name do |n| n.fullname = foo end
      def fullname=(fullname) #:nodoc: bacwards compat
        if @card.field('FN')
          raise Vpim::InvalidEncodingError, "Not allowed to add more than one FN field to a vCard."
        end
        @card << Vpim::DirectoryInfo::Field.create( 'FN', fullname );
      end

      # Set the name fields, N and FN.
      #
      # Attributes of +name+ are:
      # - family: family name
      # - given: given name
      # - additional: additional names
      # - prefix: such as "Ms." or "Dr."
      # - suffix: such as "BFA", or "Sensei"
      #
      # +name+ is a Vcard::Name.
      #
      # All attributes are optional, though have all names be zero-length
      # strings isn't really in the spirit of  things. FN's value will be set
      # to Vcard::Name#formatted if Vcard::Name#fullname isn't given a specific
      # value.
      #
      # Warning: This is the only mandatory field.
      def name #:yield:name
        x = begin
              @card.name.dup
            rescue
              Vpim::Vcard::Name.new
            end

        fn = x.fullname

        yield x

        x.fullname.strip!

        delete_if do |line|
          line.name == 'N'
        end

        @card << x.encode
        @card << x.encode_fn

        self
      end

      alias :add_name :name #:nodoc: backwards compatibility

      # Add an address field, ADR. +address+ is a Vpim::Vcard::Address.
      def add_addr # :yield: address
        x = Vpim::Vcard::Address.new
        yield x
        @card << x.encode
        self
      end

      # Add a telephone field, TEL. +tel+ is a Vpim::Vcard::Telephone.
      #
      # The block is optional, its only necessary if you want to specify
      # the optional attributes.
      def add_tel(number) # :yield: tel
        x = Vpim::Vcard::Telephone.new(number)
        if block_given?
          yield x
        end
        @card << x.encode
        self
      end

      # Add an email field, EMAIL. +email+ is a Vpim::Vcard::Email.
      #
      # The block is optional, its only necessary if you want to specify
      # the optional attributes.
      def add_email(email) # :yield: email
        x = Vpim::Vcard::Email.new(email)
        if block_given?
          yield x
        end
        @card << x.encode
        self
      end

      # Set the nickname field, NICKNAME.
      #
      # It can be set to a single String or an Array of String.
      def nickname=(nickname)
        delete_if { |l| l.name == 'NICKNAME' }

        @card << Vpim::DirectoryInfo::Field.create( 'NICKNAME', nickname );
      end

      # Add a birthday field, BDAY.
      #
      # +birthday+ must be a time or date object.
      #
      # Warning: It may confuse both humans and software if you add multiple
      # birthdays.
      def birthday=(birthday)
        if !birthday.respond_to? :month
          raise ArgumentError, 'birthday must be a date or time object.'
        end
        delete_if { |l| l.name == 'BDAY' }
        @card << Vpim::DirectoryInfo::Field.create( 'BDAY', birthday );
      end

      # Add a note field, NOTE. The +note+ String can contain newlines, they
      # will be escaped.
      def add_note(note)
        @card << Vpim::DirectoryInfo::Field.create( 'NOTE', Vpim.encode_text(note) );
      end

      # Add an instant-messaging/point of presence address field, IMPP. The address
      # is a URL, with the syntax depending on the protocol.
      #
      # Attributes of IMPP are:
      # - preferred: true - set if this is the preferred address
      # - location: home, work, mobile - location of address
      # - purpose: personal,business - purpose of communications
      #
      # All attributes are optional, and so is the block.
      #
      # The URL syntaxes for the messaging schemes is fairly complicated, so I
      # don't try and build the URLs here, maybe in the future. This forces
      # the user to know the URL for their own address, hopefully not too much
      # of a burden.
      #
      # IMPP is defined in draft-jennings-impp-vcard-04.txt. It refers to the
      # URI scheme of a number of messaging protocols, but doesn't give
      # references to all of them:
      # - "xmpp" indicates to use XMPP, draft-saintandre-xmpp-uri-06.txt
      # - "irc" or "ircs" indicates to use IRC, draft-butcher-irc-url-04.txt
      # - "sip" indicates to use SIP/SIMPLE, RFC 3261
      # - "im" or "pres" indicates to use a CPIM or CPP gateway, RFC 3860 and RFC 3859
      # - "ymsgr" indicates to use yahoo
      # - "msn" might indicate to use Microsoft messenger
      # - "aim" indicates to use AOL
      #
      def add_impp(url) # :yield: impp
        params = {}

        if block_given?
          x = Struct.new( :location, :preferred, :purpose ).new

          yield x

          x[:preferred] = 'PREF' if x[:preferred]

          types = x.to_a.flatten.compact.map { |s| s.downcase }.uniq

          params['TYPE'] = types if types.first
        end

        @card << Vpim::DirectoryInfo::Field.create( 'IMPP', url, params)
        self
      end

      # Add an X-AIM account name where +xaim+ is an AIM screen name.
      #
      # I don't know if this is conventional, or supported by anything other
      # than AddressBook.app, but an example is:
      #   X-AIM;type=HOME;type=pref:exampleaccount
      #
      # Attributes of X-AIM are:
      # - preferred: true - set if this is the preferred address
      # - location: home, work, mobile - location of address
      #
      # All attributes are optional, and so is the block.
      def add_x_aim(xaim) # :yield: xaim
        params = {}

        if block_given?
          x = Struct.new( :location, :preferred ).new

          yield x

          x[:preferred] = 'PREF' if x[:preferred]

          types = x.to_a.flatten.compact.map { |s| s.downcase }.uniq

          params['TYPE'] = types if types.first
        end

        @card << Vpim::DirectoryInfo::Field.create( 'X-AIM', xaim, params)
        self
      end


      # Add a photo field, PHOTO.
      #
      # Attributes of PHOTO are:
      # - image: set to image data to include inline
      # - link: set to the URL of the image data
      # - type: string identifying the image type, supposed to be an "IANA registered image format",
      #     or a non-registered image format (usually these start with an x-)
      #
      # An error will be raised if neither image or link is set, or if both image
      # and link is set.
      #
      # Setting type is optional for a link image, because either the URL, the
      # image file extension, or a HTTP Content-Type may specify the type. If
      # it's not a link, setting type is mandatory, though it can be set to an
      # empty string, <code>''</code>, if the type is unknown.
      #
      # TODO - I'm not sure about this API. I'm thinking maybe it should be
      # #add_photo(image, type), and that I should detect when the image is a
      # URL, and make type mandatory if it wasn't a URL.
      def add_photo # :yield: photo
        x = Struct.new(:image, :link, :type).new
        yield x
        if x[:image] && x[:link]
          raise Vpim::InvalidEncodingError, 'Image is not allowed to be both inline and a link.'
        end

        value = x[:image] || x[:link]

        if !value
          raise Vpim::InvalidEncodingError, 'A image link or inline data must be provided.'
        end

        params = {}

        # Don't set type to the empty string.
        params['TYPE'] = x[:type] if( x[:type] && x[:type].length > 0 )

        if x[:link]
          params['VALUE'] = 'URI'
        else # it's inline, base-64 encode it
          params['ENCODING'] = :b64
          if !x[:type]
            raise Vpim::InvalidEncodingError, 'Inline image data must have it\'s type set.'
          end
        end

        @card << Vpim::DirectoryInfo::Field.create( 'PHOTO', value, params )
        self
      end

      # Add a URL field, URL.
      def add_url(url)
        @card << Vpim::DirectoryInfo::Field.create( 'URL', url.to_str );
      end

      # Add a Field, +field+.
      def add_field(field)
        fieldname = field.name.upcase
        case
        when [ 'BEGIN', 'END' ].include?(fieldname)
          raise Vpim::InvalidEncodingError, "Not allowed to manually add #{field.name} to a vCard."

        when [ 'VERSION', 'N', 'FN' ].include?(fieldname)
          if @card.field(fieldname)
            raise Vpim::InvalidEncodingError, "Not allowed to add more than one #{fieldname} to a vCard."
          end
          @card << field

        else
          @card << field
        end
      end

      # Copy the fields from +card+ into self using #add_field. If a block is
      # provided, each Field from +card+ is yielded. The block should return a
      # Field to add, or nil.  The Field doesn't have to be the one yielded,
      # allowing the field to be copied and modified (see Field#copy) before adding, or 
      # not added at all if the block yields nil.
      #
      # The vCard fields BEGIN and END aren't copied, and VERSION, N, and FN are copied
      # only if the card doesn't have them already.
      def copy(card) # :yields: Field
        card.each do |field|
          fieldname = field.name.upcase
          case
          when [ 'BEGIN', 'END' ].include?(fieldname)
            # Never copy these

          when [ 'VERSION', 'N', 'FN' ].include?(fieldname) && @card.field(fieldname)
            # Copy these only if they don't already exist.

          else
            if block_given?
              field = yield field
            end

            if field
              add_field(field)
            end
          end
        end
      end

      # Delete +line+ if block yields true.
      def delete_if #:yield: line
        begin
        @card.delete_if do |line|
          yield line
        end
        rescue NoMethodError
          # FIXME - this is a hideous hack, allowing a DirectoryInfo to
          # be passed instead of a Vcard, and for it to almost work. Yuck.
        end
      end

    end
  end
end

