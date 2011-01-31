module Conversational
  module Conversation

    mattr_accessor :unknown_topic_subclass,
                   :blank_topic_subclass,
                   :parent,
                   :class_suffix

    def self.included(base)
      self.parent = base
      base.send(:include, InstanceMethods)
      base.extend ClassMethods
      if defined?(ActiveRecord::Base) && base <= ActiveRecord::Base
        base.send(:include, ActiveRecordAdditions)
      else
        base.send(:include, InstanceAttributes)
      end
    end

    module InstanceAttributes
      attr_accessor :with, :topic

      def initialize(options = {})
        self.with = options[:with]
        self.topic = options[:topic]
      end
    end

    module InstanceMethods
      # Returns the specific sublass of conversation based from the topic
      # Example:
      #
      # <tt>
      #   Class Conversation
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
      #   Conversation.exclude HelloConversation
      #
      #   hello = Conversation.new("someone", "hello")
      #   hello.details => nil
      #
      #   hello.details(:include_all => true) => #<HelloConversation topic: "hello", with: "someone">
      #
      # </tt>
      def details(options = {})
        details_subclass = Conversational::Conversation.find_subclass_by_topic(
          topic, options
        )
        if details_subclass
          self.respond_to?(:becomes) ?
            becomes(details_subclass) :
            Conversational::Conversation.becomes(
              details_subclass, self
            )
        end
      end

      def topic_defined?
        details_subclass = Conversational::Conversation.topic_defined?(topic)
      end
    end

    module ClassMethods
      def unknown_topic_subclass(value)
        Conversational::Conversation.unknown_topic_subclass = value
      end

      def blank_topic_subclass(value)
        Conversational::Conversation.blank_topic_subclass = value
      end

      def class_suffix(value)
        Conversational::Conversation.class_suffix = value
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
        Conversational::Conversation.exclude(classes)
      end
    end

    def self.topic_defined?(topic)
      self.find_subclass_by_topic(
        topic,
        :exclude_blank_unknown => true
      )
    end

    def self.find_subclass_by_topic(topic, options = {})
      subclass = nil
      if topic.nil? || topic.blank?
        unless options[:exclude_blank_unknown]
          subclass = blank_topic_subclass.constantize if blank_topic_subclass
        end
      else
        project_class_name = self.topic_subclass_name(topic)
        begin
          project_class = project_class_name.constantize
        rescue
          project_class = nil
        end
        # the subclass has been defined
        # check that it is a subclass klass
        if project_class && project_class <= parent &&
          (options[:include_all] || !self.exclude?(project_class))
            subclass = project_class
        else
          unless options[:exclude_blank_unknown]
            subclass = unknown_topic_subclass.constantize if unknown_topic_subclass
          end
        end
      end
      subclass
    end

    def self.exclude(classes)
      if classes
        if classes.is_a?(Array)
          classes.each do |class_name|
            check_exclude_options!(class_name)
          end
        else
          check_exclude_options!(classes)
        end
      end
      @@excluded_classes = classes
    end

    def self.topic_subclass_name(topic)
      topic.classify + (class_suffix || parent).to_s
    end

    private

    def self.becomes(klass, from)
      klass_instance = klass.new
      from.instance_variables.each do |instance_variable|
        klass_instance.instance_variable_set(
          instance_variable,
          from.instance_variable_get(instance_variable)
        )
      end
      klass_instance
    end

    def self.exclude?(subclass)
      if defined?(@@excluded_classes)
        if @@excluded_classes.is_a?(Array)
          @@excluded_classes.each do |excluded_class|
            break if exclude_class?(subclass)
          end
        else
          exclude_class?(subclass)
        end
      end
    end

    def self.exclude_class?(subclass)
      if @@excluded_classes.is_a?(Class)
        @@excluded_classes == subclass
      elsif @@excluded_classes.is_a?(Regexp)
        subclass.to_s =~ @@excluded_classes
      else
        excluded_class = @@excluded_classes.to_s
        begin
          excluded_class.classify.constantize == subclass
        rescue
          false
        end
      end
    end

    def self.check_exclude_options!(classes)
      raise(
        ArgumentError,
        "You must specify an Array, Symbol, Regex, String or Class or nil. You specified a #{classes.class}"
      ) unless classes.is_a?(Symbol) ||
          classes.is_a?(Regexp) ||
          classes.is_a?(String) ||
          classes.is_a?(Class)
    end
  end
end

