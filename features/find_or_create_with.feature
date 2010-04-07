Feature: Find existing conversation or create a new one
  In order easily create a new conversation if an existing one cannot be found
  As a Conversation user
  I want to be able to call find_or_create_with supplying with and the topic

  Scenario: No existing conversations - Create a new conversation
  Given no conversations exist with: "someone"
  When I call find_or_create_with("someone", "sample")
  Then a conversation should exist with topic: "sample", with: "someone"

  Scenario: An existing open, recent conversation - Get the existing conversation
  Given a conversation exists with topic: "sample", with: "someone"
  When I call find_or_create_with("someone", "sample")
  Then 1 conversations should exist

  Scenario: An existing open, old conversation - Create a new conversation
  Given a conversation exists with topic: "sample", with: "someone"
  And 24 hours have elapsed since the conversation started
  When I call find_or_create_with("someone", "sample")
  Then 2 conversations should exist

  Scenario: An existing finished, recent conversation - Create a new conversation
  Given a conversation exists with topic: "sample", with: "someone"
  And the conversation is finished
  When I call find_or_create_with("someone", "sample")
  Then 2 conversations should exist

  Scenario: An existing finished, old conversation - Create a new conversation
  Given a conversation exists with topic: "sample", with: "someone"
  And 24 hours have elapsed since the conversation started
  And the conversation is finished
  When I call find_or_create_with("someone", "sample")
  Then 2 conversations should exist

