require "rubygems"
require "rake/gempackagetask"
require "rake/rdoctask"

require "rake/testtask"
Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true
end


task :default => ["test"]

# This builds the actual gem. For details of what all these options
# mean, and other ones you can add, check the documentation here:
#
#   http://rubygems.org/read/chapter/20
#
spec = Gem::Specification.new do |s|

  # Change these as appropriate
  s.name              = "vpim"
  s.version           = "1.1"
  s.summary           = "iCalendar and vCard support for ruby"

  s.description       = 'This is a pure-ruby library for decoding and encoding vCard and iCalendar data ("personal information") called vPim.'

  s.author            = "Sam Roberts"
  s.email             = "vieuxtech@gmail.com"
  s.homepage          = "http://vpim.rubyforge.org"
  s.rubyforge_project = "vpim"

  s.has_rdoc          = true
  s.extra_rdoc_files  = ["README", "CHANGES", "COPYING", "samples/README.mutt" ]
  s.rdoc_options      = %w(--main README)

  # Add any extra files to include in the gem
  s.files             = %w(CHANGES COPYING ex_fmt_convert.rb ex_ics_api.rb Makefile mbox2vcard.rb outline.sh profile.rb profile.txt README setup.rb stamp.rb THANKS vpim.gemspec) + Dir.glob("{test,lib}/**/*")
  s.require_paths     = ["lib"]

  # If you want to depend on other gems, add them here, along with any
  # relevant versions
  # s.add_dependency("some_other_gem", "~> 0.1.0")

  # If your tests use any gems, include them here
  # s.add_development_dependency("mocha") # for example
end

# This task actually builds the gem. We also regenerate a static
# .gemspec file, which is useful if something (i.e. GitHub) will
# be automatically building a gem for this project. If you're not
# using GitHub, edit as appropriate.
#
# To publish your gem online, install the 'gemcutter' gem; Read more 
# about that here: http://gemcutter.org/pages/gem_docs
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "Build the gemspec file #{spec.name}.gemspec"
task :gemspec do
  file = File.dirname(__FILE__) + "/#{spec.name}.gemspec"
  File.open(file, "w") {|f| f << spec.to_ruby }
end

# If you don't want to generate the .gemspec file, just remove this line. Reasons
# why you might want to generate a gemspec:
#  - using bundler with a git source
#  - building the gem without rake (i.e. gem build blah.gemspec)
#  - maybe others?
task :package => :gemspec

# Generate documentation
Rake::RDocTask.new do |rd|
  rd.main = "README"
  rd.rdoc_files.include("README", "lib/**/*.rb")
  rd.rdoc_dir = "rdoc"
end

desc 'Clear out RDoc and generated packages'
task :clean => [:clobber_rdoc, :clobber_package] do
  rm "#{spec.name}.gemspec"
end
