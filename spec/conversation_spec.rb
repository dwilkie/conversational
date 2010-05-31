require 'spec_helper'

describe Conversational::Conversation do

  describe "#details" do
    let(:conversation) { Class.new }
    before {
      conversation.extend(Conversational::Conversation)
      conversation.stub!(:topic).and_return("something")
    }
    context "a subclass for this topic exists" do
      let(:subclass) { mock("Subclass") }
      before {
        Conversational::ConversationDefinition.stub!(
          :find_subclass_by_topic
        ).and_return(subclass)
      }
      it "should return the instance as a subclass" do
        conversation.should_receive(:becomes).with(subclass)
        conversation.details
      end
    end
    context "a subclass for this topic does not exist" do
      before {
        Conversational::ConversationDefinition.stub!(
          :find_subclass_by_topic
        ).and_return(nil)
      }
      it "should return nil" do
        conversation.details.should be_nil
      end
    end
  end
end
