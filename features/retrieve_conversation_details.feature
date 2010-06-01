Feature: Get the conversation specifics
  In order to get the specific conversation based on the topic and then move it along
  As a Conversation user
  I want to be able to get the specific conversation from the general one based off the topic

  Scenario: Get the details from a conversation instance
    Given a conversation exists with topic: "sample", with: "someone@example.com"
    Then the conversation details should be a SampleConversation

  Scenario: Get the details from a conversation instance
    Given a conversation exists with topic: "sample", with: "someone@example.com"
    And I configured Conversation with the following: Conversation.exclude [SampleConversation]
    Then conversation.details(:include_all => true) should be a SampleConversation
