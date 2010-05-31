require 'rails/generators'
module Conversational
  class SkeletonGenerator < Rails::Generators::Base

    def self.source_root
       @source_root ||= File.join(File.dirname(__FILE__), 'templates')
    end

    def create_conversations_directory
      empty_directory "app/conversations"
    end

    def copy_conversation_file
      copy_file "conversation.rb", "app/conversations/conversation.rb"
    end
  end
end
