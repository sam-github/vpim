## preparing

t = Time.now
starter = Time.local(t.year,t.mon, t.day) + (24 *3600)
ender = starter + 7 * 24 *3600
lattitude = 39.0
longitude = -77.0

## accessing through dynamically generated driver

require 'soap/wsdlDriver'

params = {:maxt => nil, :mint => nil, :temp => true, :dew => true,
  :pop12 => nil, :qpf => nil, :sky => nil, :snow => nil, :wspd => nil,
  :wdir => nil, :wx => nil, :waveh => nil, :icons => nil}

drv = SOAP::WSDLDriverFactory.new("http://weather.gov/forecasts/xml/DWMLgen/wsdl/ndfdXML.wsdl").create_rpc_driver
drv.wiredump_dev = STDOUT if $DEBUG
puts drv.NDFDgen(lattitude, longitude, 'time-series', starter, ender, params)

## accessing through statically generated driver

# run wsdl2ruby.rb to create needed files like this;
# wsdl2ruby.rb --wsdl http://weather.gov/forecasts/xml/DWMLgen/wsdl/ndfdXML.wsdl --type client
require 'defaultDriver.rb'
params = WeatherParametersType.new(nil, nil, true, true, nil, nil, nil, nil, nil, nil, nil, nil, nil)

drv = NdfdXMLPortType.new
drv.wiredump_dev = STDOUT if $DEBUG
puts drv.NDFDgen(lattitude, longitude, ProductType::TimeSeries, starter, ender, params)

