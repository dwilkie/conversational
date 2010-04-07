require 'spec_helper'

describe Conversation do
  before(:each) do
    @valid_attributes = {
      :topic => "something",
      :with => "someone"
    }
  end

  def define_conversation(params=nil)
    unless params && (params[:blank] || params[:unknown])
      defined_conversation_class = mock("DefinedConversation")
      defined_conversation = mock("defined_conversation")
      topic = "defined"
      topic.stub!(:+).and_return(topic)
      topic.stub!(:classify).and_return(topic)
      topic.stub!(:constantize).and_return(defined_conversation_class)
      defined_conversations = []
      Conversation.stub!(:subclasses_of).and_return(defined_conversations)
      yield(defined_conversation_class, defined_conversation, topic, defined_conversations)
    else
      if params[:unknown]
        defined_conversation_class = mock("UnknownConversation")
        defined_conversation = mock("unknown_conversation")
        Conversation.unknown_topic_subclass = defined_conversation_class
      end
      if params[:blank]
        defined_conversation_class = mock("BlankConversation")
        defined_conversation = mock("blank_conversation")
        Conversation.blank_topic_subclass = defined_conversation_class
      end
      yield(defined_conversation_class, defined_conversation)
    end
  end

  describe "#move_along!" do
    before(:each) do
      @conversation = Conversation.create!(:with => "someone", :topic => "sample")
      @conversation = @conversation.details
    end
    context "there are finishing keywords" do
      before(:each) do
        Conversation.finishing_keywords = ["stop", "halt"]
      end
      context "a finishing keyword was received" do
        it "should change the state to finished" do
          @conversation.move_along!("stop")
          @conversation.should be_finished
        end
      end
      context "a finishing keyword was not received" do
        it "should not change the state to finished" do
          @conversation.move_along!("now")
          @conversation.should_not be_finished
        end
      end
    end
    context "there are no finishing keywords" do
      it "should not change the state to finished" do
        @conversation.move_along!
        @conversation.should_not be_finished
      end
    end
  end

  describe "#find_or_create_with" do
    context "no conversation exists" do
      context "a conversation definition with this topic has been defined" do
        before(:each) do
          define_conversation do |defined_conversation_class, defined_conversation, topic, defined_conversations|
            @defined_conversation_class = defined_conversation_class
            @defined_conversation = defined_conversation
            @topic = topic
            @defined_conversations = defined_conversations
          end
        end
        context "and it is a type of conversation" do
          before(:each) do
            @defined_conversations.stub!(:include?).and_return(true)
          end
          it "should create a new conversation" do
            @defined_conversation_class.should_receive(:create!).with(:with => "someone", :topic => @topic)
            Conversation.find_or_create_with("someone", @topic)
          end
        end
        context "but it is not a type of conversation" do
          before(:each) do
            @defined_conversations.stub!(:include?).and_return(false)
          end
          context "but an unknown topic subclass has however been defined" do
            before(:each) do
              define_conversation(:unknown => true) do |unknown_conversation_class, unknown_conversation|
                @unknown_conversation_class = unknown_conversation_class
              end
            end
            it "should create a new unknown conversation" do
              @unknown_conversation_class.should_receive(:create!).with(:with => "someone", :topic => @topic)
              Conversation.find_or_create_with("someone", @topic)
            end
          end
          context "and an unknown topic subclass has not been defined" do
            before(:each) do
              Conversation.unknown_topic_subclass = nil
            end
            it "should raise an error" do
              lambda { Conversation.find_or_create_with("someone", @topic) }.should raise_error(
                       /it does not subclass Conversation/)
            end
          end
        end
      end
      context "and a conversation definition with this topic has not been defined" do
        context "but an unknown conversation definition has been defined" do
          before(:each) do
            define_conversation(:unknown => true) do |unknown_conversation_class, unknown_conversation|
              @unknown_conversation_class = unknown_conversation_class
            end
          end
          it "should create an unknown conversation" do
            @unknown_conversation_class.should_receive(:create!).with(:with => "someone", :topic => "something")
            Conversation.find_or_create_with("someone", "something")
          end
        end
        context "and an unknown conversation definition has not been defined" do
          before(:each) do
            Conversation.unknown_topic_subclass = nil
          end
          it "should raise an error" do
              lambda { Conversation.find_or_create_with("someone", "something") }.should raise_error(
                       /not defined SomethingConversation/)
          end
        end
      end
      context "the topic for conversation is blank" do
        context "but a blank conversation definition has been defined" do
          before(:each) do
            define_conversation(:blank => true) do |blank_conversation_class, blank_conversation|
              @blank_conversation_class = blank_conversation_class
            end
          end
          it "should create a blank conversation" do
            @blank_conversation_class.should_receive(:create!).with(:with => "someone", :topic => nil)
            Conversation.find_or_create_with("someone", nil)
          end
        end
        context "and a blank conversation has not been defined" do
          before(:each) do
            Conversation.blank_topic_subclass = nil
          end
          it "should raise an error" do
              lambda { Conversation.find_or_create_with("someone", nil) }.should raise_error(
                       /not defined a topic for this Conversation/)
          end
        end
      end
    end
    context "a conversation already exists" do
      before(:each) do
        # Rails 3
        # Conversation.stub_chain(:with, :last).and_return(@conversation)
        @conversation = Conversation.new(@valid_attributes)
        Conversation.stub_chain(:converser, :in_progress, :recent, :last).and_return(@conversation)
        @defined_conversation = mock("defined_conversation")
      end
      it "should return the conversation as an instance of the subclass" do
        @conversation.should_receive(:details).and_return(@defined_conversation)
        Conversation.find_or_create_with("someone", "something").should == @defined_conversation
      end
    end
  end
  describe "#details" do
    before(:each) do
      @conversation = Conversation.new(@valid_attributes)
    end
    context "a conversation definition with this topic has been defined" do
      before(:each) do
        define_conversation do |defined_conversation_class, defined_conversation, topic, defined_conversations|
          @defined_conversation_class = defined_conversation_class
          @defined_conversation = defined_conversation
          @conversation.stub!(:topic).and_return(topic)
          @defined_conversations = defined_conversations
        end
      end
      context "and it is a type of conversation" do
        before(:each) do
          @defined_conversations.stub!(:include?).and_return(true)
          @defined_conversation_class.stub!(:new).and_return(@defined_conversation)
        end
        it "should return the specific type of conversation" do
          @conversation.details.should == @defined_conversation
        end
      end
      context "but is not a type of conversation" do
        before(:each) do
          @defined_conversations.stub!(:include?).and_return(false)
        end
        context "an unknown conversation definition has however been defined" do
          before(:each) do
            define_conversation(:unknown => true) do |unknown_conversation_class, unknown_conversation|
              @unknown_conversation = unknown_conversation
              unknown_conversation_class.stub!(:new).and_return(unknown_conversation)
            end
          end
          it "should return an instance of the unknown conversation definition" do
            @conversation.details.should == @unknown_conversation
          end
        end
        context "and an unknown conversation definition has not been defined" do
          before(:each) do
            Conversation.unknown_topic_subclass = nil
          end
          it "should return nil" do
            @conversation.details.should be_nil
          end
        end
      end
    end
    context "a conversation definition with this topic has not been defined" do
      context "but an unknown conversation definition has been defined" do
        before(:each) do
          define_conversation(:unknown => true) do |unknown_conversation_class, unknown_conversation|
            @unknown_conversation = unknown_conversation
            unknown_conversation_class.stub!(:new).and_return(unknown_conversation)
          end
        end
        it "should return an instance of the unknown conversation class" do
          @conversation.details.should == @unknown_conversation
        end
      end
      context "and an unknown conversation definition has not been defined" do
        before(:each) do
          Conversation.unknown_topic_subclass = nil
        end
        it "should return nil" do
          @conversation.details.should be_nil
        end
      end
    end
    context "the topic for conversation is blank" do
      before(:each) do
        @conversation.topic = ""
      end
      context "but a blank conversation definition has been defined" do
        before(:each) do
          define_conversation(:blank => true) do |blank_conversation_class, blank_conversation|
            @blank_conversation = blank_conversation
            blank_conversation_class.stub!(:new).and_return(blank_conversation)
          end
        end
        it "should return an instance of the blank conversation definition" do
          @conversation.details.should == @blank_conversation
        end
      end
     context "and a blank conversation has not been defined" do
        before(:each) do
          Conversation.blank_topic_subclass = nil
        end
        it "should return nil" do
          @conversation.details.should be_nil
        end
      end
    end
  end
  describe "scopes" do
    before(:each) do
      @conversation = Conversation.create!(@valid_attributes)
    end
    describe "scope converser" do
      it "should find the conversation with someone" do
        Conversation.converser("someone").last.should == @conversation
      end
    end
    describe "scope recent" do
      context "the conversation is less than 24 hours old" do
        context "passing no arguments" do
          it "should find the conversation" do
            Conversation.recent.last.should == @conversation
          end
        end
      end
      context "the conversation is older than 24 hours" do
        before(:each) do
          @conversation.created_at = 24.hours.ago
          @conversation.save!
        end
        context "passing no arguments" do
          it "should not find the conversation" do
            Conversation.recent.last.should be_nil
          end
        end
        context "passing an argument" do
          it "should find the conversation" do
            Conversation.recent(25.hours.ago).last.should == @conversation
          end
        end
      end
    end
    describe "scope in_progress" do
      context "conversation is in progress" do
        it "should find the conversation" do
          Conversation.in_progress.last.should == @conversation
        end
      end
      context "conversation is finished" do
        before(:each) do
          @conversation.state = "finished"
          @conversation.save!
        end
        it "should not find the conversation" do
          Conversation.in_progress.last.should be_nil
        end
      end
    end
#    Rails 3
#    describe "scope with" do
#      context "conversation is in progress and recent" do
#        it "should find the conversation" do
#          Conversation.with("someone").last.should == @conversation
#        end
#      end
#    end
  end
end

