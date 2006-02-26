=begin
  Copyright (C) 2006 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'vpim/vcard'

module Vpim
  module Maker
    # A helper class to assist in building a vCard.
    #
    # This idea is modelled after ruby 1.8's rss/maker classes. Perhaps all these methods
    # should be added to Vpim::Vcard?
    class Vcard
      # Make a vCard for +full_name+.
      #
      # Yields +card+, a Vpim::Maker::Vcard to which fields can be added, and returns a Vpim::Vcard.
      #
      # Note that calling #add_name is required, all other fields are optional.
      def Vcard.make(full_name, &block) # :yields: +card+
        new(full_name).make(&block)
      end

      def make # :nodoc:
        yield self
        if !@initialized_N
          raise Vpim::InvalidEncodingError, 'It is mandatory to have a N field, see #add_name.'
        end
        @card
      end

      private

      def initialize(full_name) # :nodoc:
        @card = Vpim::Vcard::create
        @card << Vpim::DirectoryInfo::Field.create('FN', full_name )
        @initialized_N = false
        # pp @card
      end

      public

      # Add an arbitrary Field, +field+.
      def add_field(field)
        @card << field
      end

      # Add a name field, N.
      #
      # Warning: This is the only mandatory field, besides the full name, which
      # is added from Vcard.make's +full_name+.
      #
      # Attributes of N are:
      # - family: family name
      # - given: given name
      # - additional: additional names
      # - prefix: such as "Ms." or "Dr."
      # - suffix: such as "BFA", or "Sensei"
      #
      # All attributes are optional.
      #
      # FIXME: is it possible to deduce given/family from the full_name?
      # 
      # FIXME: Each attribute can currently only have a single String value.
      #
      # FIXME: Need to escape specials in the String.
      def add_name # :yield: n
        x = Struct.new(:family, :given, :additional, :prefix, :suffix).new
        yield x
        @card << Vpim::DirectoryInfo::Field.create(
          'N',
          x.map { |s| s ? s.to_str : '' }
          )
        @initialized_N = true
        self
      end

      # Add a address field, ADR.
      #
      # Attributes of ADR that describe the address are:
      # - pobox: post office box
      # - extended: seldom used, its not clear what it is for
      # - street: street address, multiple components should be separated by a comma, ','
      # - locality: usually the city
      # - region: usually the province or state
      # - postalcode: postal code
      # - country: country name, no standard for country naming is specified
      #
      # Attributes that describe how the address is used, and customary values, are:
      # - location: home, work - often used, can be set to other values
      # - preferred: true - often used, set if this is the preferred address
      # - delivery: postal, parcel, dom (domestic), intl (international) - rarely used
      #
      # All attributes are optional. #location and #home can be set to arrays of
      # strings.
      #
      # TODO: Add #label to support LABEL.
      #
      # FIXME: Need to escape specials in the String.
      def add_addr # :yield: adr
        x = Struct.new(
          :location, :preferred, :delivery,
          :pobox, :extended, :street, :locality, :region, :postalcode, :country
          ).new
        yield x

        values = x.to_a[3, 7].map { |s| s ? s.to_str : '' }

        # All these attributes go into the TYPE parameter.
        params = [ x[:location], x[:delivery] ]
        params << 'pref' if x[:preferred]
        params = params.flatten.uniq.compact.map { |s| s.to_str }

        paramshash = {}

        paramshash['type'] = params if params.first

        @card << Vpim::DirectoryInfo::Field.create( 'ADR', values, paramshash)
        self
      end

      # Add a telephone number field, TEL.
      #
      # +number+ is supposed to be a "X.500 Telephone Number" according to RFC 2426, if you happen
      # to be familiar with that. Otherwise, anything that looks like a phone number should be OK.
      # 
      # Attributes of TEL are:
      # - location: home, work, msg, cell, car, pager - often used, can be set to other values
      # - preferred: true - often used, set if this is the preferred telephone number
      # - capability: voice,fax,video,bbs,modem,isdn,pcs - fax is useful, the others are rarely used
      #
      # All attributes are optional, and so is the block.
      def add_tel(number) # :yield: tel
        params = {}
        if block_given?
          x = Struct.new( :location, :preferred, :capability ).new

          yield x

          x[:preferred] = 'pref' if x[:preferred]

          types = x.to_a.flatten.uniq.compact.map { |s| s.to_str }

          params['type'] = types if types.first
        end

        @card << Vpim::DirectoryInfo::Field.create( 'TEL', number, params)
        self
      end

      # Add a email address field, EMAIL.
      #
      # Attributes of EMAIL are:
      # - location: home, work - often used, can be set to other values
      # - preferred: true - often used, set if this is the preferred email address
      # - protocol: internet,x400 - internet is the default, set this for other kinds
      #
      # All attributes are optional, and so is the block.
      def add_email(email) # :yield: email
        params = {}
        if block_given?
          x = Struct.new( :location, :preferred, :protocol ).new

          yield x

          x[:preferred] = 'pref' if x[:preferred]

          types = x.to_a.flatten.uniq.compact.map { |s| s.to_str }

          params['type'] = types if types.first
        end

        @card << Vpim::DirectoryInfo::Field.create( 'EMAIL', email, params)
        self
      end

      # Add a nickname field, NICKNAME.
      def nickname=(nickname)
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
          raise Vpim::InvalidEncodingError, 'birthday doesn\'t have #month, so it is not a date or time object.'
        end
        @card << Vpim::DirectoryInfo::Field.create( 'BDAY', birthday );
      end
=begin
TODO - need text=() implemented in Field

      # Add a note field, NOTE. It can contain newlines, they will be escaped.
      def note=(note)
        @card << Vpim::DirectoryInfo::Field.create( 'NOTE', note );
      end
=end

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

          x[:preferred] = 'pref' if x[:preferred]

          types = x.to_a.flatten.uniq.compact.map { |s| s.to_str }

          params['type'] = types if types.first
        end

        @card << Vpim::DirectoryInfo::Field.create( 'IMPP', url, params)
        self
      end

      # Add an Apple style AIM account name, +xaim+ is an AIM screen name.
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

          x[:preferred] = 'pref' if x[:preferred]

          types = x.to_a.flatten.uniq.compact.map { |s| s.to_str }

          params['type'] = types if types.first
        end

        @card << Vpim::DirectoryInfo::Field.create( 'X-AIM', xaim, params)
        self
      end


      # Add a photo field, PHOTO.
      #
      # Attributes of PHOTO are:
      # - image: set to image data to inclue inline
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
        params['type'] = x[:type] if( x[:type] && x[:type].length > 0 )

        if x[:link]
          params['value'] = 'uri'
        else # it's inline, base-64 encode it
          params['encoding'] = :b64
          if !x[:type]
            raise Vpim::InvalidEncodingError, 'Inline image data must have it\'s type set.'
          end
        end

        @card << Vpim::DirectoryInfo::Field.create( 'PHOTO', value, params )
        self
      end

    end
  end
end

