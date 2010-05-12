require 'rails/generators'

class SkeletonGenerator < Rails::Generators::Base
  desc "run this generator to set up conversation"
  invoke "migration", %(create_conversations state:string topic:string)
  source_root File.expand_path("../templates", __FILE__)
  
  def copy_initializer_file
    copy_file "initializer.rb", "config/initializers/conversation.rb"
  end
end
