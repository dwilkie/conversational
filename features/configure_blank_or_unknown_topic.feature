Feature: Specify a blank or unknown conversation topic template
  In order to converse when the topic is blank or unknown
  As a Conversation user
  I want to be able to specify a conversation template to use when the topic is blank or unknown

  Scenario Outline: Specify a blank or unknown conversation topic
    Given I configured my <topic> conversation topic template as SampleConversation
    When I start up a conversation with a <topic> topic
    Then the conversation details should be a SampleConversation

  Examples:
  | topic  |
  | blank  |
  | unknown|

