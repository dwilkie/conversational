require 'spec_helper'

# TODO test .class_suffix
describe Conversational::Conversation do

  class Conversation
    include Conversational::Conversation
  end

  class DrinkingConversation < Conversation
  end

  class SmokingConversation < Conversation
  end

  class DrivingBlahBlah < Conversation
  end

  class FlyingConversation
  end

  class BusinessConversation < Conversation
  end

  it "should respond to '.unknown_topic_subclass'" do
    Conversation.should respond_to(:unknown_topic_subclass)
  end

  it "should respond to '.blank_topic_subclass'" do
    Conversation.should respond_to(:blank_topic_subclass)
  end

  it "should respond to '.class_suffix'" do
    Conversation.should respond_to(:class_suffix)
  end

  let!(:conversation) { Conversation.new }

  before do
    Conversation.exclude(nil)
    Conversation.unknown_topic_subclass(nil)
    Conversation.blank_topic_subclass(nil)
    Conversation.class_suffix(nil)
  end

  describe ".exclude" do
    it "should accept a string" do
      lambda {
        Conversation.exclude "something"
        }.should_not raise_error
    end
    it "should accept a symbol" do
      lambda {
        Conversation.exclude :defined_conversation
        }.should_not raise_error
    end
    it "should accept a regex" do
      lambda {
        Conversation.exclude /something/i
        }.should_not raise_error
    end
    it "should accept a Class" do
      lambda {
        Conversation.exclude(DrinkingConversation)
      }.should_not raise_error
    end
    it "should accept an Array where the elements are a Class, String, Symbol or Regexp" do
      lambda {
        Conversation.exclude ["Something", DrinkingConversation, /something/i, :something]
        }.should_not raise_error
    end
    it "should accept nil" do
      lambda {
        Conversation.exclude nil
        }.should_not raise_error
    end
    it "should not accept anything else" do
      lambda {
        Conversation.exclude({})
        }.should raise_error(/You specified a Hash/)
    end
  end

  describe "#topic" do
    it "should set the topic" do
      conversation.topic = "hello"
      conversation.topic.should == "hello"
    end
  end

  describe "#topic_defined?" do
    shared_examples_for "#topic_defined? for an excluded class" do
      it "should return nil" do
        conversation.topic_defined?.should be_nil
      end
    end

    context "a class with this topic is defined" do
      before { conversation.topic = "drinking" }
      it "should be true" do
        conversation.topic_defined?.should be_true
      end

      context "but it is not a subclass of the module which includes Conversation" do
        before { conversation.topic = "flying" }
        it_should_behave_like "#topic_defined? for an excluded class"
      end

      context "but it has been excluded" do
        context "by passing the class" do
          before { Conversation.exclude(DrinkingConversation) }
          it_should_behave_like "#topic_defined? for an excluded class"
        end

        context "by passing an Array of classes" do
          before { Conversation.exclude([DrinkingConversation])}
          it_should_behave_like "#topic_defined? for an excluded class"
        end

        context "by passing a regexp" do
          before { Conversation.exclude(/^Drinking/) }
          it_should_behave_like "#topic_defined? for an excluded class"
        end

        context "by passing a symbol" do
          before { Conversation.exclude(:drinking_conversation) }
          it_should_behave_like "#topic_defined? for an excluded class"
        end

        context "by passing a string" do
          before { Conversation.exclude("DrinkingConversation") }
          it_should_behave_like "#topic_defined? for an excluded class"
        end
      end
    end

    context "a conversation for this topic is not defined" do
      before do
        Conversation.unknown_topic_subclass(SmokingConversation)
        conversation.topic = "drinking_tea"
      end
      it_should_behave_like "#topic_defined? for an excluded class"
    end
  end

  describe "#details" do
    shared_examples_for "#details for an excluded class" do
      it "should return nil" do
        conversation.details.should be_nil
      end
      context "when '.unknown_topic_subclass' is set" do
        before {Conversation.unknown_topic_subclass(SmokingConversation)}
        it "should return an instance of the unknown_topic_subclass" do
          conversation.details.should be_a(SmokingConversation)
        end
      end
    end

    context "a conversation for this topic has been defined" do
      before { conversation.topic = "drinking" }
      it "should return the instance as a subclass" do
        conversation.details.should be_a(DrinkingConversation)
      end

      context "but it is not a subclass of the module which includes Conversation" do
        before { conversation.topic = "flying" }
        it_should_behave_like "#details for an excluded class"
      end

      context "but it has been excluded" do
        before { Conversation.exclude(DrinkingConversation) }
        it_should_behave_like "#details for an excluded class"
      end
    end

    context "a conversation for this topic has not been defined" do
      before { conversation.topic = "drinking_tea" }
      it_should_behave_like "#details for an excluded class"
    end

    shared_examples_for "#details for a blank or nil topic" do
      it "should return nil" do
        conversation.details.should be_nil
      end

      context "'.blank_topic_subclass' is set" do
        before {Conversation.blank_topic_subclass(FlyingConversation)}
        it "should return an instance of the blank_topic_subclass" do
          conversation.details.should be_a(FlyingConversation)
        end
      end
    end

    context "the conversation has a blank topic" do
      before { conversation.topic = "" }
      it_should_behave_like "#details for a blank or nil topic"
    end

    context "the conversation has no topic" do
      before { conversation.topic = nil }
      it_should_behave_like "#details for a blank or nil topic"
    end

    context "a conversation for this topic ended with 's' has been defined" do
      before { conversation.topic = "business" }
      it "should return the instance as a subclass" do
        conversation.details.should be_a(BusinessConversation)
      end
    end
  end
end

