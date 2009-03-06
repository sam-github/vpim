=begin
  Copyright (C) 2009 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'sinatra/base'

# Auto-choose our handler based on the environment.
# TODO Code should be in Sinatra, and should handle Thin, Mongrel, etc.
Sinatra::Base.configure do
  server = Sinatra::Base.server
  Sinatra::Base.set :server, Proc.new {
      if ENV.include?("PHP_FCGI_CHILDREN")
        break "fastcgi" # Must NOT be the correct class name!
      elsif ENV.include?("REQUEST_METHOD")
        break "cgi" # Must NOT be the correct class name!
      else
        # Fall back on whatever it was going to be.
        server
      end
  }
end

