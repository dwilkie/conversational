require 'spec_helper'

describe Conversation do
  let(:valid_attributes) { {:topic => "something", :with => "someone"} }

  def define_conversation(params=nil)
    defined_conversation = {}
    unless params && (params[:blank] || params[:unknown])
      defined_conversation[:class] = mock("DefinedConversation")
      defined_conversation[:instance] = mock("defined_conversation")
      topic = "defined"
      topic.stub!(:+).and_return(topic)
      topic.stub!(:classify).and_return(topic)
      topic.stub!(:constantize).and_return(defined_conversation[:class])
      defined_conversation[:topic] = topic
      defined_conversation[:array] = []
      Conversation.stub!(:subclasses_of).and_return(defined_conversation[:array])
    else
      if params[:unknown]
        defined_conversation[:class] = mock("UnknownConversation")
        defined_conversation[:instance] = mock("unknown_conversation")
        Conversation.unknown_topic_subclass = defined_conversation[:class]
      end
      if params[:blank]
        defined_conversation[:class] = mock("BlankConversation")
        defined_conversation[:instance] = mock("blank_conversation")
        Conversation.blank_topic_subclass = defined_conversation[:class]
      end
    end
    defined_conversation
  end

  describe ".find_or_create_with" do
    context "when no conversation exists" do
      context "but a conversation definition with this topic has been defined" do
        let(:defined_conversation) { defined_conversation = define_conversation }
        context "and it is a type of conversation" do
          before {
            defined_conversation[:array].stub!(:include?).and_return(true)
          }
          it "should create a new conversation" do
            defined_conversation[:class].should_receive(:create!).with(
              :with => "someone", :topic => defined_conversation[:topic]
            )
            Conversation.find_or_create_with("someone", defined_conversation[:topic])
          end
        end
        context "but it is not a type of conversation" do
          before {
            defined_conversation[:array].stub!(:include?).and_return(false)
          }
          context "but an unknown topic subclass has however been defined" do
            let(:unknown_conversation) { define_conversation(:unknown => true) }
            it "should create a new unknown conversation" do
              unknown_conversation[:class].should_receive(:create!).with(
                :with => "someone", :topic => defined_conversation[:topic]
              )
              Conversation.find_or_create_with("someone", defined_conversation[:topic])
            end
          end
          context "and an unknown topic subclass has not been defined" do
            before {
              Conversation.unknown_topic_subclass = nil
            }
            it "should raise an error" do
              lambda {
                Conversation.find_or_create_with(
                  "someone", defined_conversation[:topic]
                )
              }.should raise_error(/it does not subclass Conversation/)
            end
          end
        end
      end
      context "and a conversation definition with this topic has not been defined" do
        context "but an unknown conversation definition has been defined" do
          let(:unknown_conversation) { define_conversation(:unknown => true) }
          it "should create an unknown conversation" do
            unknown_conversation[:class].should_receive(:create!).with(
              :with => "someone", :topic => "something"
            )
            Conversation.find_or_create_with("someone", "something")
          end
        end
        context "and an unknown conversation definition has not been defined" do
          before {
            Conversation.unknown_topic_subclass = nil
          }
          it "should raise an error" do
              lambda {
                Conversation.find_or_create_with(
                  "someone", "something"
                )
              }.should raise_error(/not defined SomethingConversation/)
          end
        end
      end
      context "the topic for conversation is blank" do
        context "but a blank conversation definition has been defined" do
          let(:blank_conversation) { define_conversation(:blank => true) }
          it "should create a blank conversation" do
            blank_conversation[:class].should_receive(:create!).with(
              :with => "someone", :topic => nil
            )
            Conversation.find_or_create_with("someone", nil)
          end
        end
        context "and a blank conversation has not been defined" do
          before(:each) do
            Conversation.blank_topic_subclass = nil
          end
          it "should raise an error" do
              lambda {
                Conversation.find_or_create_with("someone", nil)
              }.should raise_error(/not defined a topic for this Conversation/)
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
  
  describe "#details" do
    let(:conversation) { Conversation.new(valid_attributes) }
    context "a conversation definition with this topic has been defined" do
      let(:defined_conversation) { define_conversation }
      before {
        conversation.stub!(:topic).and_return(defined_conversation[:topic])
      }
      context "and it is a type of conversation" do
        before {
          defined_conversation[:array].stub!(:include?).and_return(true)
          defined_conversation[:class].stub!(:new).and_return(
            defined_conversation[:instance])
        }
        it "should return the specific type of conversation" do
          conversation.details.should == defined_conversation[:instance]
        end
      end
      context "but is not a type of conversation" do
        before {
          defined_conversation[:array].stub!(:include?).and_return(false)
        }
        context "an unknown conversation definition has however been defined" do
          let(:unknown_conversation) { define_conversation(:unknown => true) }
          before {
            unknown_conversation[:class].stub!(:new).and_return(
              unknown_conversation[:instance]
            )
          }
          it "should return an instance of the unknown conversation definition" do
            conversation.details.should == unknown_conversation[:instance]
          end
        end
        context "and an unknown conversation definition has not been defined" do
          before {
            Conversation.unknown_topic_subclass = nil
          }
          it "should return nil" do
            conversation.details.should be_nil
          end
        end
      end
    end
    context "a conversation definition with this topic has not been defined" do
      context "but an unknown conversation definition has been defined" do
        let(:unknown_conversation) { define_conversation(:unknown => true) }
        before {
          unknown_conversation[:class].stub!(:new).and_return(
            unknown_conversation[:instance]
          )
        }
        it "should return an instance of the unknown conversation class" do
          conversation.details.should == unknown_conversation[:instance]
        end
      end
      context "and an unknown conversation definition has not been defined" do
        before {
          Conversation.unknown_topic_subclass = nil
        }
        it "should return nil" do
          conversation.details.should be_nil
        end
      end
    end
    context "the topic for conversation is blank" do
      before {
        conversation.topic = ""
      }
      context "but a blank conversation definition has been defined" do
        let(:blank_conversation) { define_conversation(:blank => true) }
        before {
          blank_conversation[:class].stub!(:new).and_return(
            blank_conversation[:instance]
          )
        }
        it "should return an instance of the blank conversation definition" do
          conversation.details.should == blank_conversation[:instance]
        end
      end
     context "and a blank conversation has not been defined" do
        before {
          Conversation.blank_topic_subclass = nil
        }
        it "should return nil" do
          conversation.details.should be_nil
        end
      end
    end
  end
  describe "scopes" do
    let(:conversation) { Conversation.create!(valid_attributes) }
    # remove this before block after 
    # http://github.com/rspec/rspec-rails/issues#issue/53
    # has been resolved
    before {
      tmp = conversation
    }
    describe ".converser" do
      it "should find the conversation with someone" do
        Conversation.converser("someone").last.should == conversation
      end
    end
    describe ".recent" do
      context "the conversation is less than 24 hours old" do
        context "passing no arguments" do
          it "should find the conversation" do
            Conversation.recent.last.should == conversation
          end
        end
      end
      context "the conversation is older than 24 hours" do
        before {
          conversation.created_at = 24.hours.ago
          conversation.save!
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
          conversation.finish
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
end
