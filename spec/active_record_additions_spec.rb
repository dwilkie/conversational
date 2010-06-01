# See support/conversation.rb

require 'spec_helper'

describe Conversational::ActiveRecordAdditions do
  let(:valid_attributes) { {:with => "someone"} }
  describe "scopes" do
    let!(:conversation) { Conversation.create!(valid_attributes) }
    describe ".converser" do
      it "should find the conversation with someone" do
        Conversation.converser("someone").last.should == conversation
      end
    end
    describe ".recent" do
      context "the conversation was updated less than 24 hours ago" do
        context "passing no arguments" do
          it "should find the conversation" do
            Conversation.recent.last.should == conversation
          end
        end
      end
      context "the conversation was updated more than 24 hours ago" do
        before {
          Conversation.record_timestamps = false
          conversation.updated_at = 24.hours.ago
          conversation.save!
          Conversation.record_timestamps = true
        }
        context "passing no arguments" do
          it "should not find the conversation" do
            Conversation.recent.last.should be_nil
          end
        end
        context "passing an argument" do
          it "should find the conversation" do
            Conversation.recent(25.hours.ago).last.should == conversation
          end
        end
      end
    end
    describe ".in_progress" do
      context "conversation is in progress" do
        it "should find the conversation" do
          Conversation.in_progress.last.should == conversation
        end
      end
      context "conversation is finished" do
        before {
          conversation.state = "finished"
          conversation.save!
        }
        it "should not find the conversation" do
          Conversation.in_progress.last.should be_nil
        end
      end
    end
    describe ".with" do
      context "conversation is in progress and recent" do
        it "should find the conversation" do
          Conversation.with("someone").last.should == conversation
        end
      end
    end
  end
  
  describe ".find_or_create_with" do
    context "when no existing conversation exists with 'someone'" do
      context "but a subclass for this topic exists and has not been excluded" do
        let(:subclass) { mock("Subclass") }
        before {
          Conversational::ConversationDefinition.stub!(
            :find_subclass_by_topic
          ).with("something").and_return(subclass)
        }
        it "should create an instance of the subclass" do
          subclass.should_receive(:create!).with(
            :with => "someone", :topic => "something"
          )
          Conversation.find_or_create_with("someone", "something")
        end
      end
      context "and a subclass for this topic also does not exist" do
        before {
          Conversational::ConversationDefinition.stub!(
            :find_subclass_by_topic
          ).and_return(nil)
        }
        context "and the topic is blank" do
          it "should raise an error" do
            lambda {
              Conversation.find_or_create_with("someone", nil)
            }.should raise_error(/not defined a blank_topic_subclass/)
          end
        end
        context "though the topic is not blank" do
          it "should still raise an error" do
            lambda {
              Conversation.find_or_create_with(
                "someone", "something"
              )
            }.should raise_error(/not defined SomethingConversation/)
          end
        end
      end
    end
    context "a conversation already exists" do
      let(:conversation) { Conversation.new(valid_attributes) }
      let(:defined_conversation) { mock("defined_conversation") }
      before {
        Conversation.stub_chain(:with, :last).and_return(conversation)
      }
      it "should return the conversation as an instance of the subclass" do
        conversation.should_receive(:details).and_return(defined_conversation)
        Conversation.find_or_create_with(
          "someone", "something"
        ).should == defined_conversation
      end
    end
  end
end
