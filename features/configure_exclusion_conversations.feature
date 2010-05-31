Feature: Configure exclusion conversations
  In order to allow conversations to exist in a project that should not be found
           when using Conversation.details or Conversation.find_or_create_with
  As a Conversation user
  I want to be able to configure which conversations should be excluded
  
  Scenario Outline: Configure exclusion conversations
    Given I configured Conversation with the following: <configuration>
    And a conversation exists with topic: "sample", with: "someone@example.com"
    Then the conversation details should be nil

    Examples:
      | configuration                                                              |
      | Conversation.exclude [SampleConversation]                                  |
      | Conversation.exclude SampleConversation                                    |
      | Conversation.exclude "sample_conversation"                                 |
      | Conversation.exclude "SampleConversation"                                  |
      | Conversation.exclude :sample_conversation                                  |
      | Conversation.exclude /sample/i                                             |
      | Conversation.exclude [/sample/, "sample_conversation", SampleConversation] |
