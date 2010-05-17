Feature: Specify an unknown conversation topic template
  In order to converse when the topic is unknown
  As a Conversation user
  I want to be able to specify a conversation template to use when the topic is unknown

  Scenario: Specify an unknown conversation topic
    Given I configured Conversation with the following: Conversation.unknown_topic_subclass = SampleConversation
    When I start up a conversation with an unknown topic
    Then the conversation details should be a SampleConversation
