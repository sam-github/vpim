require 'etc'
require 'pp'
require 'rss/maker'
require 'socket'
require 'webrick'
require 'vpim/icalendar'
require 'vpim/vcard'

#--------------------------------------------------------------------------------
# Load DNSSD support, if possible.
# TODO - should be in net/dns/dnssd
# FIXME - doesn't work with dnssd
@avoid_native = true
begin
  if @avoid_native
    raise LoadError
  else
    require 'dnssd'
  end
rescue LoadError
  begin
    require 'net/dns/mdns-sd'
    DNSSD = Net::DNS::MDNSSD
  rescue LoadError
    DNSSD = nil
  end
end

#--------------------------------------------------------------------------------
# Set up server environment.

# Find the user's name and host.

require 'etc'

$user = Etc.getpwuid(Process.uid).gecos
$host = Socket.gethostname

$services = []

$stuff = []

def register(name, path, protocol = 'http')
  # $services << DNSSD.register(name, '_http._tcp', 'local', $port, 'path' => path )

  puts "register #{name.inspect} on path #{path.inspect} with #{protocol}"

  $stuff << [name, path, protocol]
end

# Create a HTTP server, possibly on a dynamic port.
#   - Dynamic ports don't actually work well. While it is true we can advertise them,
#     non-DNSSD aware clients will store the hostname and port when they subscribe to
#     a calendar, but when the server restarts the port will be different. Not good.
$port = 8191

server = WEBrick::HTTPServer.new( :Port => $port )

if $port == 0
  # Server may have created multiple listeners, all on a different dynamically
  # assigned port.
  families = Socket.getaddrinfo(nil, 1, Socket::AF_UNSPEC, Socket::SOCK_STREAM, 0, Socket::AI_PASSIVE)

  listeners = []

  families.each do |af, one, dns, addr|
    listeners << TCPServer.new(addr, $port)
    $port = listeners.first.addr[1] unless $port != 0
  end

  listeners.each do |s|
    puts "listen on #{s.addr.inspect}"
  end

  # So we replace them with our TCPServer sockets which are all on the same
  # (dynamically assigned) port.
  server.listeners.each do |s| s.close end
  server.listeners.replace listeners
  server.config[:Port] = $port
end

server.config[:MimeTypes]['ics'] = 'text/calendar'
server.config[:MimeTypes]['vcf'] = 'text/directory'

#--------------------------------------------------------------------------------
# Mount services

##### Vcard Birthdays as iCalendar
=begin
$vcf_bday_file = 'vpim-bday.vcf'
$vcf_bday_path = '/vcf/bday.ics'

class VcfBdayIcsServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, resp)
    cal = Vpim::Icalendar.create

    open($vcf_bday_file) do |vcf|
      Vpim::Vcard.decode(vcf).each do |card|
        begin
          bday = card.birthday
          if bday
            cal.push Vpim::Icalendar::Vevent.create_yearly(
              card.birthday,
              "Birthday for #{card['fn'].strip}"
              )
            $stderr.puts "#{card['fn']} -> bday #{cal.events.last.dtstart}"
          end
        rescue
          $stderr.puts $!
          $stderr.puts $!.backtrace.join("\n")
        end
      end
    end

    resp.body = cal.encode
    resp['content-type'] = 'text/calendar'

    # Is this necessary, or is it default?
    raise WEBrick::HTTPStatus::OK
  end
end

server.mount( $vcf_bday_path, VcfBdayIcsServlet )

register( "Calendar for all the Birthdays in my vCards", $vcf_bday_path, 'webcal' )
=end

##### iCalendar as calendars
# Export local calendars two different ways
=begin
$ical_folder = File.expand_path( "~/Library/Calendars" )

#
# Here we write a servlet to display all the allowed calendars with
# webcal links, so they open in iCal.
#
$ical_include = /^[A-Z]/
$ical_title = "My Calendars"

class IcalIcsServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, resp)
    body = ''
#   body << @options.inspect

    folder, include, exclude = *@options

    path = req.path_info

#   body << "\n"
#   body << "path=#{path.inspect}\n"

    all = Dir.entries(folder).select do |f| f =~ /\.ics$/ end

    if include
      all.reject! do |f| !(f =~ include) end
    end
    if exclude
      all.reject! do |f| f =~ exclude end
    end

#   body << "#{all.inspect}\n"

    if(path == '')
      body << "<ul>\n"
      all.each do |f|
        n = f.sub('.ics', '')
        body << "<li><a href=\"webcal://#{$host}:#{$port}/calfile/#{f}\">#{n}</a>\n"
      end
      body << "</ul>\n"
    end

    resp.body = body
    resp['content-type'] = 'text/html'
    raise WEBrick::HTTPStatus::OK
  end
end

server.mount( '/calweb', IcalIcsServlet, $ical_folder, $ical_include)

register( "My Calendars as webcal:// Feeds", '/calweb' )

#
# We use the WEBrick file servlet to actually serve calendar files.
# FIXME - this means that if you guess someone's calendar name, you can
# download it, despite the rudimentary security.
#
server.mount( '/calfile', WEBrick::HTTPServlet::FileHandler, $ical_folder, :FancyIndexing=>true )

# For debugging...
register( 'My Calendar Folder', '/calfile' )

=end

##### iCalendar/todo as RSS
=begin
$ics_todo_title = 'My Todo Items as an RSS Feed'
$ics_todo_path  = "/ics/todo.rss"

class IcalTodoRssServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, resp)   
    rss = RSS::Maker.make("0.9") do |maker|
      title = $ics_todo_title
      link = 'http:///'
      maker.channel.title = title
      maker.channel.link = link
      maker.channel.description = title
      maker.channel.language = 'en-us'

      # These are required, or RSS::Maker silently returns nil!
      maker.image.url = "maker.image.url"
      maker.image.title = "maker.image.title"

      Dir[ $ical_folder + "/*.ics" ].each do |file|
        # TODO: use the open with a block variant
        Vpim::Icalendar.decode(File.open(file)).each do |cal|
          cal.todos.each do |todo|
            if !todo.status || todo.status.upcase != "COMPLETED"
              item = maker.items.new_item
              item.title = todo.summary
              item.link =  todo.properties['url'] || link
              item.description = todo.description || todo.summary
            end
          end
        end
      end
    end

    resp.body = rss.to_s
    resp['content-type'] = 'text/xml'

    raise WEBrick::HTTPStatus::OK
  end
end

server.mount( $ics_todo_path, IcalTodoRssServlet )

register( $ics_todo_title, $ics_todo_path )
=end

##### Local calendars

require "vpim/agent/calendars"

$ical_folder = File.expand_path( "~/Library/Calendars" )

class CalendarsServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, resp)
    body = ''
#   body << @options.inspect

    folder = *@options

    # TODO Should be longer lived
    repo = Vpim::Repo::Apple3.new($ical_folder)
    rest = Vpim::Agent::Calendars.new(repo)
    path = Vpim::Agent::Path.new(req.request_uri, req.path)

    begin
      body, form = rest.get(path)
      status = 200
    rescue Vpim::Agent::NotFound
      body = $!.to_s
      form = "text/plain" # should be HTML!
      status = 404
    end

    resp.status = status
    resp.body = body
    resp['content-type'] = form
  end
end

server.mount( '/calendars', CalendarsServlet, $ical_folder )

register( "Calendars", '/calendars' )

#--------------------------------------------------------------------------------
## Top-level page.

$vpim_title = "vAgent for #{$user}"

class VpimServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, resp)
    body = <<"EOF"
<h1>#{$vpim_title}</h1>

See:
<ul>
EOF

    $stuff.each do |name,path,protocol|
      #body << "<li><a href=\"#{protocol}://#{$host}:#{$port}#{path}\">#{name}</a>\n"
      #
      # $host is wrong, it lacks the domain - we should derive this from how
      # we are called, or just leave it out.
      body << "<li><a href=\"#{path}\">#{name}</a>\n"
    end

    body << "</ul>\n"

    resp.body = body
    resp['content-type'] = 'text/html'
    raise WEBrick::HTTPStatus::OK
  end
end

server.mount( '/', VpimServlet )

#--------------------------------------------------------------------------------
# Run server

if DNSSD
  $services << DNSSD.register($vpim_title, '_http._tcp', 'local', $port, 'path' => '/' )
end

['INT', 'TERM'].each do |signal| 
  trap(signal) do
    server.shutdown
    $services.each do |s|
      s.stop
    end
  end
end

server.start


