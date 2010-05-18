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
      defined_conversation[:array].stub!(:include?).and_return(true)
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

  describe "scopes" do
    let!(:conversation) { Conversation.create!(valid_attributes) }
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

  describe ".converse" do
    it "should accept a block" do
      lambda {
        Conversation.converse do |with, notice|
        end
        }.should_not raise_error
    end
    it "should not accept anything else" do
      lambda {
        Conversation.converse("something")
        }.should raise_error
    end
  end
  
  describe ".unknown_topic_subclass" do
    it "should be a class attribute" do
      unknown_topic_conversation = mock("UnknownTopicConversation")
      Conversation.unknown_topic_subclass = unknown_topic_conversation
      Conversation.unknown_topic_subclass.should == unknown_topic_conversation
    end
  end

  describe ".blank_topic_subclass" do
    it "should be a class attribute" do
      blank_topic_conversation = mock("BlankTopicConversation")
      Conversation.blank_topic_subclass = blank_topic_conversation
      Conversation.blank_topic_subclass.should == blank_topic_conversation
    end
  end
  
  describe ".finishing_keywords" do
    it "should be a class attribute" do
      finishing_keywords = ["stop", "cancel"]
      Conversation.finishing_keywords = finishing_keywords
      Conversation.finishing_keywords.should == finishing_keywords
    end
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
      some_class = mock("SomeClass", :superclass => Class)
      some_class.stub!(:is_a?).with(Class).and_return(true)
      lambda {
        Conversation.exclude some_class
        }.should_not raise_error
    end
    it "should accept an Array where the elements are a Class, String, Symbol or Regexp" do
      some_class = mock("SomeClass", :superclass => Class)
      some_class.stub!(:is_a?).with(Class).and_return(true)
      lambda {
        Conversation.exclude ["Something", some_class, /something/i, :something]
        }.should_not raise_error
    end
    it "should accept nil" do
      lambda {
        Conversation.exclude nil
        }.should_not raise_error
    end
    it "should not accept anything else" do
      some_class = mock("SomeClass")
      lambda {
        Conversation.exclude some_class
        }.should raise_error(/You specified a /)
    end
  end

#      context "and defining a class 'DefinedConversation < Conversation'" do
#        let(:defined_conversation) { define_conversation }
#        before {
#          excluded_class = "DefinedConversation"
#          excluded_class.stub!(:constantize).and_return(
#            defined_conversation[:class]
#          )
#          Conversation.exclude excluded_class
#        }
#        context "then Conversation.find_or_create_with('someone', 'defined')" do
#          it "should raise an error" do
#            lambda {
#              Conversation.find_or_create_with(
#                "someone", defined_conversation[:topic]
#              )
#            }.should raise_error(/it has been excluded/)
#          end
#        end

#        context "then Conversation.new(:topic => 'defined').details" do
#          let(:conversation) { Conversation.new(valid_attributes) }
#          before {
#            conversation.stub!(:topic).and_return(defined_conversation[:topic])
#          }
#          it "should return nil" do
#            conversation.details.should be_nil
#          end
#        end




  describe ".find_or_create_with" do
    context "when no existing conversation exists with 'someone'" do
      context "but a conversation definition with this topic has been defined" do
        let(:defined_conversation) { define_conversation }
        context "and it subclasses conversation" do
          before {
            defined_conversation[:array].stub!(:include?).and_return(true)
          }
          context "and it has not been excluded" do
            before {
              Conversation.exclude nil
            }
            it "should create a new conversation" do
              defined_conversation[:class].should_receive(:create!).with(
                :with => "someone", :topic => defined_conversation[:topic]
              )
              Conversation.find_or_create_with(
                "someone", defined_conversation[:topic]
              )
            end
          end
          context "but it has been excluded" do
            before {
              Conversation.stub!(:exclude?).and_return(true)
            }
            context "and an unknown topic subclass has been defined" do
              let(:unknown_conversation) { define_conversation(:unknown => true) }
              it "should create a new unknown conversation" do
                unknown_conversation[:class].should_receive(:create!).with(
                  :with => "someone", :topic => defined_conversation[:topic]
                )
                Conversation.find_or_create_with(
                  "someone", defined_conversation[:topic]
                )
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
                }.should raise_error(/it has been excluded/)
              end
            end
          end
          context "and an unknown topic subclass has not been defined" do
            before {
              Conversation.unknown_topic_subclass = nil
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
                  Conversation.exclude excluded_class
                }
                it "should raise an error" do
                  lambda {
                    Conversation.find_or_create_with(
                      "someone", defined_conversation[:topic]
                    )
                  }.should raise_error(/it has been excluded/)
                end
              end
              context "by setting Conversation.exclude DefinedConversation" do
                before {
                  excluded_class = defined_conversation[:class]
                  defined_conversation[:class].stub!(:superclass).and_return(Class)
                  defined_conversation[:class].stub!(:is_a?).with(
                    Class
                    ).and_return(true)
                  Conversation.exclude defined_conversation[:class]
                }
                it "should raise an error" do
                  lambda {
                    Conversation.find_or_create_with(
                      "someone", defined_conversation[:topic]
                    )
                  }.should raise_error(/it has been excluded/)
                end
              end
              context "by setting Conversation.exclude /defined/i" do
                before {
                  Conversation.exclude /defined/i
                }
                it "should raise an error" do
                  lambda {
                    Conversation.find_or_create_with(
                      "someone", defined_conversation[:topic]
                    )
                  }.should raise_error(/it has been excluded/)
                end
              end
              context "by setting Conversation.exclude [/defined/i]" do
                before {
                  Conversation.exclude [/defined/i]
                }
                it "should raise an error" do
                  lambda {
                    Conversation.find_or_create_with(
                      "someone", defined_conversation[:topic]
                    )
                  }.should raise_error(/it has been excluded/)
                end
              end
            end
          end
        end
        context "but it is not a type of conversation" do
          before {
            defined_conversation[:array].stub!(:include?).and_return(false)
          }
          context "but an unknown topic subclass has been defined" do
            let(:unknown_conversation) { define_conversation(:unknown => true) }
            it "should create a new unknown conversation" do
              unknown_conversation[:class].should_receive(:create!).with(
                :with => "someone", :topic => defined_conversation[:topic]
              )
              Conversation.find_or_create_with(
                "someone", defined_conversation[:topic]
                )
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
      context "and the topic for conversation is blank" do
        context "but a blank conversation definition has been defined" do
          let(:blank_conversation) { define_conversation(:blank => true) }
          it "should create a blank conversation" do
            blank_conversation[:class].should_receive(:create!).with(
              :with => "someone", :topic => nil
            )
            Conversation.find_or_create_with("someone", nil)
          end
        end
        context "and a blank conversation definition has not been defined" do
          before(:each) do
            Conversation.blank_topic_subclass = nil
          end
          it "should raise an error" do
              lambda {
                Conversation.find_or_create_with("someone", nil)
              }.should raise_error(/not defined a blank_topic_subclass/)
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
      context "and it's a type of conversation" do
        before {
          defined_conversation[:array].stub!(:include?).and_return(true)
        }
        context "and it has not been excluded" do
          before {
            Conversation.exclude nil
            defined_conversation[:class].stub!(:new).and_return(
              defined_conversation[:instance]
            )
          }
          it "should return the specific type of conversation" do
            conversation.details.should == defined_conversation[:instance]
          end
        end
        context "but it has been excluded" do
          before {
            Conversation.stub!(:exclude?).and_return(true)
          }
          context "an unknown conversation definition has been defined" do
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
        context "and an unknown topic subclass has not been defined" do
          before {
            Conversation.unknown_topic_subclass = nil
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
                Conversation.exclude excluded_class
              }
              it "should return nil" do
                conversation.details.should be_nil
              end
            end
            context "by setting Conversation.exclude DefinedConversation" do
              before {
                excluded_class = defined_conversation[:class]
                defined_conversation[:class].stub!(:superclass).and_return(Class)
                defined_conversation[:class].stub!(:is_a?).with(
                  Class
                  ).and_return(true)
                Conversation.exclude defined_conversation[:class]
              }
              it "should return nil" do
                conversation.details.should be_nil
              end
            end
            context "by setting Conversation.exclude /defined/i" do
              before {
                Conversation.exclude /defined/i
              }
              it "should return nil" do
                conversation.details.should be_nil
              end
            end
            context "by setting Conversation.exclude [/defined/i]" do
              before {
                Conversation.exclude [/defined/i]
              }
              it "should return nil" do
                conversation.details.should be_nil
              end
            end
          end
        end
      end
      context "but is not a type of conversation" do
        before {
          defined_conversation[:array].stub!(:include?).and_return(false)
        }
        context "an unknown conversation definition has been defined" do
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
end
