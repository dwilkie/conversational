Feature: Specify a blank conversation topic template
  In order to converse when the topic is blank
  As a Conversation user
  I want to be able to specify a conversation template to use when the topic is blank
  
  Scenario: Specify a blank conversation topic
    Given I configured Conversation with the following: Conversation.blank_topic_subclass = SampleConversation
    When I start up a conversation with an blank topic
    Then the conversation details should be a SampleConversation
