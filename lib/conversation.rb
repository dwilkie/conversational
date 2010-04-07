# Conversation
#
# Allows you to have stateful conversations with your users over SMS, email
# or whatever communications network you like. For example you could use conversation
# to accept multistep commands from users over SMS to perform some task.
#
# == Setup
# The generator script <tt>rails g conversation</tt> or <tt>script/generate conversation</tt>
# adds the following files:
# config/initializers/chatterbox.rb
# config/initializers/conversation.rb
# db/migrate/xxx_create_conversation.rb
#
# Conversation uses Chatterbox by default but you don't have to use it
#
# == Useage
# Consider the following example to offer a use a drink
# see DrinkingConversation under the app/models directory for the full implementation
#
# DrinkingConversation < Conversation
#   def move_along!(message)
#     # your logic for the drinking conversation goes here
#     say("something") # => Sends a message to the user "something"
#   end
# end
#
# somewhere in your app....
# conversation = Conversation.create!(:with => "0812345678", :topic => "drinking")
# => Creates a new DrinkingConversation with 0812345678
# conversation.details.move_along!
# => Sends an SMS to 0812345678 with "Would you like a drink?"
#
# IncomingSMSController < ApplicationController
#   def create(params)
#     # An incoming SMS is received from 0812345678 with the message "yes"
#     possible_topic = params[:message].split(" ").first
#     conversation = Conversation.find_or_create_with(params[:number], possible_topic)
#     # => returns the active DrinkingConversation with 0812345678
#     conversation.move_along!(params[:message])
#     => Sends an SMS to 0812345678 with "I suggest beer"
#   end
# end
#
# == Creation
# <tt>conversation = Conversation.create(:with => "someone", :topic => "something")</tt>
# will create and return a new instance Conversation with the state: "new", with: "someone"
# and topic: "something"
#
# The returned value will be an instance of the superclass Conversation.
# <tt>conversation.details</tt> gives you the instance as a SomethingConversation
# provided that SomethingConversation is defined and subclasses Conversation.
#
# If SomethingConversation is not defined or does not subclass conversation
# <tt>conversation.details</tt> will try and return an instance of the <tt>unknown_topic_subclass</tt>
# which can be set via <tt>Conversation.unknown_topic_subclass=MyUnknownConversation</tt>
#
# If the unknown topic subclass has not been defined then calling <tt>conversation.details</tt>
# will return nil
#
# Similarly you can create Conversations with no topic
# <tt>conversation = Conversation.create(:with => "someone")</tt>
#
# In this case calling <tt>conversation.details</tt> with return and instance of the <tt>blank_topic_subclass</tt>
# which can be set via <tt>Conversation.blank_topic_subclass=MyBlankConversation</tt> or nil
# if it has not been defined

# == Finding
# Default
# <tt>Conversation.with("someone")</tt>
# Will return all conversations that are not "finished" with "someone" in the last 24 hours
#
# If a conversation has the state: "finished" or is older than 24 hours
# it will not be returned
#
# Overriding defaults
# <tt>Conversation.converser("someone")</tt>
# Will return all conversations with "someone"
#
# <tt>Conversation.in_progress</tt>
# Will return all conversations that are not "finished" within the last 24 hours
#
# <tt>Conversation.recent</tt>
# Will return all conversations in the last 24 hours
#
# <tt>Conversation.with("someone")</tt> is just a shortcut for <tt>Conversation.converser("someone").in_progress.recent</tt>
#
# Just like with create the returned conversations will be an instances of the superclass Conversation.
# Use <tt>conversation.details</tt> on each member to get the specific type of Conversation
#
# <tt>Conversation.find_or_create_with("someone", "something")</tt>
# This will either return an instance of the most recent conversation with "someone"
# that is not "finished" and is within the last 24hrs as a SomethingConversation.
#
# If no conversation is found it will create and return a new instance of SomethingConversation
# Following the same rules as for <tt>conversation.details</tt>
# Here, however if there is not unknown topic subclass defined or no blank topic subclass defined
# and SomethingConversation is not defined, then an error will be raised.
#
# == Configuration
# === Configure Conversation to use Chatterbox
# In an initializer put the following code:
# Conversation.converse do |with, notice|
#  Chatterbox.notify(:summary => notice) do |via|
#    via["Chatterbox::Services::Email"] = {:to => with}
#  end
# end
#
# Conversation will now use the Chatterbox email service to send notifications
#
# === Define finishing keywords
# <tt>Conversation.finishing_keywords = ["stop", "cancel", "end", "whatever"]</tt>
# Now when you call <tt>super("cancel")</tt> from your Conversation subclass
# it will change the conversations state to "finished"
#
# === Define an unknown topic subclass
# <tt>Conversation.unknown_topic_subclass = UnknownTopicConversation</tt>
# Now when you call <tt>Conversation.find_or_create_with("someone", "something")</tt>
# and SomethingConversation has not been defined you will get an instance of
# UnknownTopicConversation instead of an error

# === Define a blank topic subclass
# <tt>Conversation.blank_topic_subclass = BlankTopicConversation</tt>
# Now when you call <tt>Conversation.find_or_create_with("someone")</tt>
# you will get an instance of BlankTopicConversation instead of an error

require "aasm"
class Conversation < ActiveRecord::Base
  include AASM
  aasm_column :state
  aasm_initial_state :new
  aasm_state :new
  aasm_state :finished

  cattr_accessor :unknown_topic_subclass
  cattr_accessor :blank_topic_subclass
  cattr_accessor :finishing_keywords

  validates_presence_of :with, :state

  named_scope :converser, lambda { |with| { :conditions => ["with=?", with] }}
  named_scope :in_progress, :conditions => ["state != ?", "finished"]
  named_scope :recent, lambda { |*args| { :conditions => ["created_at > ?", (args.first || 24.hours.ago)] }}
  named_scope :with, lambda { |with| converser(with).in_progress.recent }

#  Rails 3
#  scope :converser, lambda { |with| where(:with=> with) }
#  scope :in_progress, where("state != ?", "finished")
#  scope :recent, lambda { |*args| where("created_at > ?", (args.first || 24.hours.ago)) }
#  scope :with, lambda { |with| converser(with).in_progress.recent }

  # Register a service for sending notifications
  #
  # ===== Example:
  #
  # Conversation.converse do |with, notice|
  #  Chatterbox.notify(:summary => notice) do |via|
  #    via["Chatterbox::Services::Email"] = {:to => with}
  #  end
  # end
  def self.converse(&blk)
    @@notification = blk
  end

  # Finds or creates a new conversation with someone for a specified topic.
  # The topic is only used if a new conversation needs to be started
  # For example, let's say and incoming email comes in.from someone@example
  # with the subject hello.
  # When you call find_or_create_with("someone@example.com", "hello")
  # It will first look to see if a conversation exists using the default options
  # (see scopes). If it does then it will ignore the topic argument and return
  # that conversation. If a conversation does not exist then it will use topic
  # to try and create a new conversation or if a topic conversation does not exist
  # it will use the unknown_topic_subclass if that is defined.
  def self.find_or_create_with(with, topic)
    # note this will become "with" in rails 3
    default_find = self.converser(with).in_progress.recent.last
    if default_find
      default_find.details
    else
      subclass = find_subclass_by_topic(topic)
      if subclass.nil?
        if topic && !topic.blank?
          subclass_name = self.topic_subclass_name(topic)
          raise(ArgumentError,
            "You have either not defined #{subclass_name} or it does not subclass #{self.to_s}. You can either define #{subclass_name} as a subclass of #{self.to_s} or define an unknown_topic_subclass for #{self.to_s}")
        else
          raise(ArgumentError,
            "You have not defined a topic for this #{self.to_s}. You can either define a topic as a subclass of #{self.to_s} or define a blank_topic_subclass for #{self.to_s}")
        end
      end
      subclass.create!(:with => with, :topic => topic)
    end
  end

  # Returns if the conversation is finished
  def finished?
    state == "finished"
  end

  # Returns the specific subclass of conversation for the current topic
  # or if the topic is blank it returns the blank_topic_subclass if defined
  # or if the topic is unknown it returns the unknown_topic_subclass if defined
  def details
    details_subclass = self.class.find_subclass_by_topic(topic)
    self.becomes(details_subclass) if details_subclass
  end

  protected
    # Called from a subclass to deliver the message
    def say(message)
      @@notification.call(with, message)
    end

    # Overrriden in a subclass to move a conversation along. If you call super in a subclass
    # it will check if the message is a finishing keyword and mark the conversation
    # as finished if it is
    def move_along!(message=nil)
      self.state = "finished" if @@finishing_keywords && @@finishing_keywords.include?(message)
      self.save!
    end

  private #no doc
    def self.find_subclass_by_topic(topic)
      subclass = nil
      if topic.nil? || topic.blank?
        subclass = @@blank_topic_subclass if @@blank_topic_subclass
      else
        project_class_name = self.topic_subclass_name(topic)
        begin
          project_class = project_class_name.constantize
          # the subclass has been defined
          # check that it is a subclass of this class
          if subclasses_of(self).include?(project_class)
            subclass = project_class
          else
            subclass = @@unknown_topic_subclass if @@unknown_topic_subclass
          end
        rescue
          # the subclass has not been defined
          subclass = @@unknown_topic_subclass if @@unknown_topic_subclass
        end
      end
      subclass
    end

    def self.topic_subclass_name(topic)
      topic.classify + self.to_s
    end
end

