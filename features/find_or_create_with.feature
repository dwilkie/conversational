Feature: Find existing conversation or create a new one
  In order to easily create a new conversation if an existing one cannot be found
  As a Conversation user
  I want to be able to call find_or_create_with supplying who with and the topic

  Scenario: No conversations exist
    Given no conversations exist with: "someone"
    When I call find_or_create_with("someone", "sample")
    Then a conversation should exist with topic: "sample", with: "someone"

  Scenario: A recent conversation exists
    Given a conversation exists with topic: "sample", with: "someone"
    When I call find_or_create_with("someone", "sample")
    Then 1 conversations should exist

  Scenario: An old conversation exists
    Given a conversation exists with topic: "sample", with: "someone"
    And 24 hours have elapsed since the conversation was last updated
    When I call find_or_create_with("someone", "sample")
    Then 2 conversations should exist

  Scenario: An finished conversation exists
    Given a conversation exists with topic: "sample", with: "someone"
    And the conversation is finished
    When I call find_or_create_with("someone", "sample")
    Then 2 conversations should exist
  
  Scenario: No conversation exists and the subclass has been excluded
    Given a conversation exists with topic: "sample", with: "someone"
    And I configured Conversation with the following: Conversation.exclude [SampleConversation]
    When I call find_or_create_with("someone", "sample")
    Then 1 conversations should exist

