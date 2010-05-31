module Conversational
  module Conversation
    def self.included(base)
      base.extend ClassMethods
      ConversationDefinition.klass = base
      if defined?(ActiveRecord::Base) && base <= ActiveRecord::Base
        base.send(:include, ActiveRecordAdditions)
      end
    end

    # Returns the specific sublass of conversation based from the topic
    # Example:
    # 
    # <tt>
    #   Class Conversation < ActiveRecord::Base
    #     include Conversational::Conversation
    #   end
    # 
    #   Class HelloConversation < Conversation
    #   end
    #
    #   Class GoodbyeConversation < Conversation
    #   end
    #
    #   hello = Conversation.new("someone", "hello")
    #   hello.details => #<HelloConversation topic: "hello", with: "someone">
    #
    #   unknown = Conversation.new("someone", "cheese")
    #   unknown.details => nil
    #
    #   Conversation.unknown_topic_subclass = HelloConversation
    #
    #   unknown = Conversation.new("someone", "cheese")
    #   unknown.details => #<HelloConversation topic: "cheese", with: "someone">
    #
    #   blank = Conversation.new("someone")
    #   blank.details => nil
    #
    #   Conversation.blank_topic_subclass = GoodbyeConversation
    #
    #   blank = Conversation.new("someone")
    #   blank.details => #<GoodbyeConversation topic: nil, with: "someone">
    #
    # </tt>
    def details
      details_subclass = ConversationDefinition.find_subclass_by_topic(topic)
      self.becomes(details_subclass) if details_subclass
    end

    protected
      # Called from a subclass to deliver the message
      def say(message)
        ConversationDefinition.notification.call(with, message)
      end

    module ClassMethods
      def unknown_topic_subclass=(klass)
        ConversationDefinition.unknown_topic_subclass = klass
      end
      
      def unknown_topic_subclass
        ConversationDefinition.unknown_topic_subclass
      end
      
      def blank_topic_subclass=(klass)
        ConversationDefinition.blank_topic_subclass = klass
      end
      
      def blank_topic_subclass
        ConversationDefinition.blank_topic_subclass
      end

      # Register a service for sending notifications
      #
      # Example:
      #
      # <tt>
      #   Conversation.converse do |with, message|
      #     OutgoingTextMessage.create!(with, message).send
      #   end
      # </tt>
      def converse(&blk)
        ConversationDefinition.notification = blk
      end

      # Register classes which will not be treated as conversations
      # when you use #details or Conversation.find_or_create_with
      #
      # Example:
      #
      # Consider the following situation where you define AbstractConversation
      # that MonkeyConversations inherits from. You want to work with MonkeyConversation
      # but you never want to work with AbstractConversation directly.
      #
      # <tt>
      #   class AbstractConversation < Conversation
      #   end
      # 
      #   class MonkeyConversation < AbstractConversation
      #   end
      #
      #   class UnknownTopicConversation < AbstractConversation
      #   end
      #
      #   class IncomingTextMessage < ActiveRecord::Base
      #   end
      #
      #   class IncomingTextMessagesController < ApplicationController
      #     def create
      #       IncomingTextMessage.create(params[:message_text], params[:number])
      #     end
      #   end
      # </tt>
      #
      # Now what happens when a user sends in a message like "monkey"
      # <tt>
      #   message = IncomingTextMessage.last
      #   topic = message.text.split(" ").first
      #   => "monkey"
      #   number = message.number
      #   => "123456789"
      #   conversation = Conversation.new(:with => number, :topic => topic).details
      #   => #<MonkeyConversation topic: "monkey", with: "123456789">
      # </tt>

      # No problem here you will work with MonkeyConversation directly. But what if
      # the user sends in a message like "abstract"?
      # <tt>
      #   message = IncomingTextMessage.last
      #   topic = message.text.split(" ").first
      #   => "abstract"
      #   number = message.number
      #   => "123456789"
      #   conversation = Conversation.new(:with => number, :topic => topic).details
      #   => #<AbstractConversation topic: "abstract", with: "123456789">
      # </tt>
      # Now you're are about to work with AbstractConversation directly
      # which is not what you want. Let's fix it
      # <tt>
      #   # config/initializers/conversation.rb
      #   Conversation.exclude AbstractConversation
      #   Conversation.unknown_topic_subclass = UnkownTopicConversation
      # </tt>
      #
      # <tt>
      #   message = IncomingTextMessage.last
      #   topic = message.text.split(" ").first
      #   => "abstract"
      #   number = message.number
      #   => "123456789"
      #   conversation = Conversation.new(:with => number, :topic => topic).details
      #   => #<UnknownTopicConversation topic: "abstract", with: "123456789">
      # </tt>
      #
      # <tt>Conversation.exclude</tt> accepts the following
      # * Class: <tt>Conversation.exclude AbstractConversation</tt>
      # * Array: <tt>Conversation.exclude [AbstractConversation, OtherConversation]</tt>
      # * Symbol: <tt>Conversation.exclude :abstract_conversation</tt>
      # * String: <tt>Conversation.exclude "abstract_conversation"</tt>
      # * Regexp: <tt>Conversation.exclude /abstract/i</tt>

      def exclude(classes)
        ConversationDefinition.exclude(classes)
      end
    end
  end
end
