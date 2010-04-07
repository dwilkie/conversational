Feature: Set up Conversation with Chatterbox
  In order to user Chatterbox to send notifications with Conversation
  As a Conversation user
  I want to be able to specify a service in which conversations are sent

  Scenario: User configures Conversation to use the Chatterbox email service
    Given the user has configured Chatterbox to use the Chatterbox email service
    And the user has configured Conversation to use the Chatterbox email service
    When a notification is sent from Conversation
    Then the Chatterbox email service should be used to deliver it

