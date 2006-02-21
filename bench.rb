require 'benchmark'
require 'pp'
require 'vpim/icalendar'

unless ARGV.first
	ARGV << "~/Library/Calendars"
end

@cal = []

ARGV.each do |dir|
	@cal.concat(Dir.glob(File.expand_path(dir) + '/*.ics'))
end

pp @cal

Benchmark.bmbm do |x|
	@cal.each do |file|
		unfold =  Vpim.unfold(open(file))
		collect = unfold.collect { |line| Vpim::DirectoryInfo::Field.decode(line) }
		expand = Vpim.expand(collect)

		x.report(file + ' - decode')  { Vpim::Icalendar.decode(open(file)) }
		x.report(file + ' - unfold')  { Vpim.unfold(open(file)) }
		x.report(file + ' - field')  { unfold.collect { |line| Vpim::DirectoryInfo::Field.decode(line) } }
		x.report(file + ' - expand')  { Vpim.expand(collect) }
		x.report(file + ' - decodex')  { Vpim::Icalendar.decode(nil, expand) }
	end
end

