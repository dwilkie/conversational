require 'spec_helper'

describe DrinkingConversation do
  before(:each) do
    @valid_attributes = {
      :topic => "drinking",
      :with => "someone"
    }
  end

  describe "#move_along!" do
    before(:each) do
      @conversation = DrinkingConversation.create!(@valid_attributes)
    end
    context "conversation is new" do
      it "should ask the user if they would like a drink" do
        @conversation.should_receive(:say).with("Would you like a drink?")
        @conversation.move_along!
      end
      it "should update the conversation state to offered_drink" do
        @conversation.move_along!
        @conversation.state.should == "offered_drink"
      end
    end
    context "already offered the user a drink" do
      before(:each) do
        @conversation.state = "offered_drink"
        @conversation.save!
      end
      context "they say yes" do
        it "should suggest beer" do
          @conversation.should_receive(:say).with("I suggest Beer")
          @conversation.move_along!("yes")
        end
      end
      context "they say no" do
        it "should say You've changed" do
          @conversation.should_receive(:say).with("You've changed")
          @conversation.move_along!("no")
        end
      end
      context "they say something else..." do
        it "should suggest scotch" do
          @conversation.should_receive(:say).with("I suggest Scotch")
          @conversation.move_along!("piss off")
        end
      end
      it "should update the conversation state to finished" do
        @conversation.move_along!
        @conversation.state.should == "finished"
      end
    end
  end
end

