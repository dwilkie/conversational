Feature: Find existing conversations
  In order to find an active conversation with a user
  As a Conversation user
  I want to be able to find the conversation easily

  Background:
    Given a conversation exists with topic: "sample", with: "someone@example.com"

  Scenario: Find an open conversation within the last 24 hours
    Given 23 hours have elapsed since the conversation started
    Then I should be able to find a conversation with: "someone@example.com"

  Scenario: Find an open conversation older that 24 hours
    Given 24 hours have elapsed since the conversation started
    Then I should not be able to find a conversation with: "someone@example.com"

  Scenario: Find a finished conversation
    Given 1 hour has elapsed since the conversation started
    And the conversation is finished
    Then I should not be able to find a conversation with: "someone@example.com"

