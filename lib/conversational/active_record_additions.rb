module Conversational
  module ActiveRecordAdditions
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      attr_accessor :finishing_keywords

      def converser(with)
        scoped.where("with = ?", with)
      end

      def in_progress
        scoped.where("state != ? OR state IS NULL", "finished")
      end

      def recent(time = nil)
        time ||= 24.hours.ago
        scoped.where("updated_at > ?", time)
      end

      def with(with)
        scoped.converser(with).in_progress.recent
      end

      # Finds an existing conversation with using the defaults or
      # creates a new conversation and returns the specific conversation based
      # on the conversation topic.
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
      #   Conversation.create!("someone", "hello")
      #   existing_conversation = Conversation.find_or_create_with(
      #     "someone",
      #     "goodbye"
      #   ) => #<HelloConversation topic: "hello", with: "someone">
      #
      #   Conversation.exclude HelloConversation
      #
      #   existing_conversation = Conversation.find_or_create_with(
      #     "someone",
      #     "goodbye"
      #   ) => #<HelloConversation topic: "hello", with: "someone">
      #
      #   existing_conversation.destroy
      #
      #   non_existing_conversation = Conversation.find_or_create_with(
      #     "someone",
      #     "goodbye"
      #   ) => #<GoodbyeConversation topic: "goodbye", with: "someone">
      #
      #   non_existing_conversation.destroy
      #
      #   Conversation.exclude GoodbyeConversation
      #
      #   non_existing_conversation = Conversation.find_or_create_with(
      #     "someone",
      #     "goodbye"
      #   ) => BOOM! (Raises Error)
      #
      #   unknown_conversation = Conversation.find_or_create_with(
      #     "someone",
      #     "cheese"
      #   ) => BOOM! (Raises Error)
      #
      #   Conversation.unknown_topic_subclass = HelloConversation
      #
      #   unknown_conversation = Conversation.find_or_create_with(
      #     "someone",
      #     "cheese"
      #   ) => #<HelloConversation topic: "hello", with: "someone">
      #
      #   unknown_conversation.destroy
      #
      #   blank_conversation = Conversation.find_or_create_with(
      #     "someone"
      #   ) => BOOM! (Raises Error)
      #
      #   Conversation.blank_topic_subclass = GoodbyeConversation
      #
      #   blank_conversation = Conversation.find_or_create_with(
      #     "someone"
      #   ) => #<GoodbyeConversation topic: "goodbye", with: "someone">
      #
      # </tt>
      def find_or_create_with(with, topic)
        if default_find = self.with(with).last
          default_find.details(:include_all => true)
        else
          subclass = Conversational::Conversation.find_subclass_by_topic(topic)
          if subclass.nil?
            if topic && !topic.blank?
              subclass_name = Conversational::Conversation.topic_subclass_name(topic)
              raise(
                 ArgumentError,
                "You have either not defined #{subclass_name} it does not subclass #{self.to_s}, or it has been excluded. You can either define #{subclass_name} as a subclass of #{self.to_s} or define an unknown_topic_subclass for #{self.to_s}"
              )
            else
              raise(
                 ArgumentError,
                "You have not defined a blank_topic_subclass for #{self.to_s} so conversations without a topic are not allowed."
              )
            end
          end
          subclass.create!(:with => with, :topic => topic)
        end
      end
    end
  end
end

