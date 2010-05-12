require 'rails/generators'

class ConversationGenerator < Rails::Generators::Base
  invoke "migration", %(create_conversations state:string topic:string)
end
