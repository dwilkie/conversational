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

