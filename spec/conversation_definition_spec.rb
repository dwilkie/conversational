require 'spec_helper'

describe Conversational::ConversationDefinition do
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
      defined_conversation[:class].stub!(:<=).and_return(true)
    else
      if params[:unknown]
        defined_conversation[:class] = mock("UnknownConversation")
        defined_conversation[:instance] = mock("unknown_conversation")
        Conversational::ConversationDefinition.unknown_topic_subclass = defined_conversation[:class]
      end
      if params[:blank]
        defined_conversation[:class] = mock("BlankConversation")
        defined_conversation[:instance] = mock("blank_conversation")
        Conversational::ConversationDefinition.blank_topic_subclass = defined_conversation[:class]
      end
    end
    defined_conversation
  end

  describe ".exclude" do
    it "should accept a string" do
      lambda {
        Conversational::ConversationDefinition.exclude "something"
        }.should_not raise_error
    end
    it "should accept a symbol" do
      lambda {
        Conversational::ConversationDefinition.exclude :defined_conversation
        }.should_not raise_error
    end
    it "should accept a regex" do
      lambda {
        Conversational::ConversationDefinition.exclude /something/i
        }.should_not raise_error
    end
    it "should accept a Class" do
      some_class = mock("SomeClass", :superclass => Class)
      some_class.stub!(:is_a?).with(Class).and_return(true)
      lambda {
        Conversational::ConversationDefinition.exclude some_class
        }.should_not raise_error
    end
    it "should accept an Array where the elements are a Class, String, Symbol or Regexp" do
      some_class = mock("SomeClass", :superclass => Class)
      some_class.stub!(:is_a?).with(Class).and_return(true)
      lambda {
        Conversational::ConversationDefinition.exclude ["Something", some_class, /something/i, :something]
        }.should_not raise_error
    end
    it "should accept nil" do
      lambda {
        Conversational::ConversationDefinition.exclude nil
        }.should_not raise_error
    end
    it "should not accept anything else" do
      some_class = mock("SomeClass")
      lambda {
        Conversational::ConversationDefinition.exclude some_class
        }.should raise_error(/You specified a /)
    end
  end

  describe ".find_subclass_by_topic" do
    context "a conversation definition with this topic has been defined" do
      let(:defined_conversation) { define_conversation }
      context "and it subclasses conversation" do
        before {
          defined_conversation[:class].stub!(:<=).and_return(true)
        }
        context "and it has not been excluded" do
          before {
            Conversational::ConversationDefinition.exclude nil
          }
          it "should return the conversation definition class" do
            Conversational::ConversationDefinition.find_subclass_by_topic(
              defined_conversation[:topic]
            ).should == defined_conversation[:class]
          end
        end
        context "but it has been excluded" do
          before {
            Conversational::ConversationDefinition.stub!(:exclude?).and_return(true)
          }
          context "and an unknown topic subclass has been defined" do
            let!(:unknown_conversation) { define_conversation(:unknown => true) }
            it "should return the unknown conversation subclass" do
              Conversational::ConversationDefinition.find_subclass_by_topic(
                 defined_conversation[:topic]
              ).should == unknown_conversation[:class]
            end
          end
          context "and an unknown topic subclass has not been defined" do
            before {
              Conversational::ConversationDefinition.unknown_topic_subclass = nil
            }
            it "should return nil" do
              Conversational::ConversationDefinition.find_subclass_by_topic(
                defined_conversation[:topic]
              ).should be_nil
            end
          end
        end
        context "and an unknown topic subclass has not been defined" do
          before {
            Conversational::ConversationDefinition.unknown_topic_subclass = nil
          }
          context "and the conversation has been excluded" do
            context "by setting Conversation.exclude 'defined_conversation'" do
              before {
                excluded_class = "defined_conversation"
                excluded_class.stub_chain(
                  :classify,
                  :constantize).and_return(
                  defined_conversation[:class]
                )
                Conversational::ConversationDefinition.exclude excluded_class
              }
              it "should return nil" do
                Conversational::ConversationDefinition.find_subclass_by_topic(
                  defined_conversation[:topic]
                ).should be_nil
              end
            end
            context "by setting Conversation.exclude DefinedConversation" do
              before {
                excluded_class = defined_conversation[:class]
                defined_conversation[:class].stub!(:superclass).and_return(Class)
                defined_conversation[:class].stub!(:is_a?).with(
                  Class
                  ).and_return(true)
                Conversational::ConversationDefinition.exclude(
                  defined_conversation[:class]
                )
              }
              it "should return nil" do
                Conversational::ConversationDefinition.find_subclass_by_topic(
                  defined_conversation[:topic]
                ).should be_nil
              end
            end
            context "by setting Conversation.exclude /defined/i" do
              before {
                Conversational::ConversationDefinition.exclude /defined/i
              }
              it "should return nil" do
                Conversational::ConversationDefinition.find_subclass_by_topic(
                  defined_conversation[:topic]
                ).should be_nil
              end
            end
            context "by setting Conversation.exclude [/defined/i]" do
              before {
                Conversational::ConversationDefinition.exclude [/defined/i]
              }
              it "should return nil" do
                Conversational::ConversationDefinition.find_subclass_by_topic(
                  defined_conversation[:topic]
                ).should be_nil
              end
            end
          end
        end
      end
      context "but it is not a type of conversation" do
        before {
          defined_conversation[:class].stub!(:<=).and_return(false)
        }
        context "but an unknown topic subclass has been defined" do
          let!(:unknown_conversation) { define_conversation(:unknown => true) }
          it "should return the unknown conversation subclass" do
            Conversational::ConversationDefinition.find_subclass_by_topic(
              defined_conversation[:topic]
            ).should == unknown_conversation[:class]
          end
        end
        context "and an unknown topic subclass has not been defined" do
          before {
            Conversational::ConversationDefinition.unknown_topic_subclass = nil
          }
          it "should return nil" do
            Conversational::ConversationDefinition.find_subclass_by_topic(
              defined_conversation[:topic]
            ).should be_nil
          end
        end
      end
    end
    context "and a conversation definition with this topic has not been defined" do
      context "but an unknown conversation definition has been defined" do
        let!(:unknown_conversation) { define_conversation(:unknown => true) }
        it "should return the unknown conversation subclass" do
          Conversational::ConversationDefinition.find_subclass_by_topic(
            "something"
          ).should == unknown_conversation[:class]
        end
      end
      context "and an unknown conversation definition has not been defined" do
        before {
          Conversational::ConversationDefinition.unknown_topic_subclass = nil
        }
        it "should return nil" do
          Conversational::ConversationDefinition.find_subclass_by_topic(
            "someone"
          ).should be_nil
        end
      end
    end
    context "and the topic for conversation is blank" do
      context "but a blank conversation definition has been defined" do
        let!(:blank_conversation) { define_conversation(:blank => true) }
        it "should return the blank conversation subclass" do
          Conversational::ConversationDefinition.find_subclass_by_topic(
            nil
          ).should == blank_conversation[:class]
        end
      end
      context "and a blank conversation definition has not been defined" do
        before(:each) do
          Conversational::ConversationDefinition.blank_topic_subclass = nil
        end
        it "should return nil" do
          Conversational::ConversationDefinition.find_subclass_by_topic(
            nil
          ).should be_nil
        end
      end
    end
  end
end
