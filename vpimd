#!/opt/local/bin/ruby -w

require 'webrick'
require 'rss/maker'
require 'vpim/icalendar'
require 'vpim/vcard'

# Notes on debugging with dnssd API: check system.log, it should give info.

#require 'pp'
#module Kernel
#  def to_pp
#    s = PP.pp(self, '')
#    s.chomp!
#    s
#  end
#end

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

@services = []

$stuff = []

def register(name, path, protocol = 'http')
  #@services << DNSSD.register(name, '_http._tcp', 'local', $port, 'path' => path )
  puts "register #{name.inspect} on path #{path.inspect} with #{protocol}"

  $stuff << [name, path, protocol]
end

# Find the user's name and host.

require 'etc'

$user = Etc.getpwnam(Etc.getlogin).gecos
$host = Socket.gethostname

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

$vcf_bday_file = '_all.vcf'
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

##### iCalendar as calendars

$ical_folder = File.expand_path( "~/Library/Calendars" )
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
        body << "<li><a href=\"webcal://#{$host}:#{$port}/x/#{f}\">#{n}</a>\n"
      end
      body << "</ul>\n"
    end

    resp.body = body
    resp['content-type'] = 'text/html'
    raise WEBrick::HTTPStatus::OK
  end
end

server.mount( '/x', IcalIcsServlet, $ical_folder, $ical_include)

register( "Other", '/x', 'webcal' )

server.mount( '/ical', WEBrick::HTTPServlet::FileHandler, $ical_folder, :FancyIndexing=>true )

register( $ical_title, '/ical' )

##### iCalendar/todo as RSS

$ics_todo_title = 'The "todo" items from my Calendars'
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
        # todo: use the open with a block variant
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


#--------------------------------------------------------------------------------
## Top-level page.

$vpim_title = "vPim for #{$user}"

class VpimServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, resp)
    body = <<"EOF"
<h1>#{$vpim_title}</h1>

This the virtual "personal information" page for #{$user}.

You can access:
<ul>
EOF

    $stuff.each do |name,path,protocol|
      body << "<li><a href=\"#{protocol}://#{$host}:#{$port}#{path}\">#{name}</a>\n"
    end

    body << "</ul>\n"

    resp.body = body
    resp['content-type'] = 'text/html'
    raise WEBrick::HTTPStatus::OK
  end
end

server.mount( '/', VpimServlet )

@services << DNSSD.register($vpim_title, '_http._tcp', 'local', $port, 'path' => '/' )

#--------------------------------------------------------------------------------
# Run server

['INT', 'TERM'].each do |signal| 
  trap(signal) do
    server.shutdown
    @services.each do |s|
      s.stop
    end
  end
end

server.start

