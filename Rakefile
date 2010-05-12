require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the conversation plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'spec'
  t.libs << 'features'
  t.pattern = 'spec/**/*_spec.rb'
  t.verbose = true
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "conversation"
    gemspec.summary = "Have stateful conversations with your users"
    gemspec.description = "Have stateful conversations with your users over SMS, email or whichever service you like"
    gemspec.email = "dwilkie@gmail.com"
    gemspec.add_runtime_dependency "state_machine", ">0.9.1"
    gemspec.homepage = "http://github.com/dwilkie/conversation"
    gemspec.authors = ["David Wilkie"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

desc 'Generate documentation for the conversation plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Conversation'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

