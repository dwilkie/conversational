Feature: Configure finishing keywords
  In order to provide a customise the defaults for finishing a conversation
  As a Conversation user
  I want to be able to provide custom finishing keywords which will termininate
         a conversation

  Background:
    Given I configure Conversation with following finishing keywords: "cancel, stop"
    And a sample_conversation exists with topic: "sample", with: "someone"

  Scenario: Check cancel
    When I move the sample_conversation along with: "cancel"
    Then the sample_conversation should be finished

  Scenario: Check stop
    When I move the sample_conversation along with: "stop"
    Then the sample_conversation should be finished

