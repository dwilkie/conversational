class Conversation < ActiveRecord::Base
  state_machine :state, :initial => :new do
    event :finish do
      transition all => :finished
    end
  end

  cattr_accessor :unknown_topic_subclass
  cattr_accessor :blank_topic_subclass
  cattr_accessor :finishing_keywords

  validates_presence_of :with, :state

  scope :converser, lambda { |with| where(:with=> with) }
  scope :in_progress, where("state != ?", "finished")
  scope :recent, lambda { |*args| where("created_at > ?", (args.first || 24.hours.ago)) }
  scope :with, lambda { |with| converser(with).in_progress.recent }

  # Register a service for sending notifications
  #
  # ===== Example:
  #
  # Conversation.converse do |with, notice|
  #   Mail.deliver do
  #     to with
  #     from "someone@example.com"
  #     subject notice
  #     body notice
  #   end
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
    default_find = self.with(with).last
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
      finish if @@finishing_keywords && @@finishing_keywords.include?(message)
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

