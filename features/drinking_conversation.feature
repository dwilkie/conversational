Feature: Have a conversation with a user about drinking
  In order to suggest a suitable beverage for a user
  As a virtual waiter application
  I want to be able to have a conversation over email
         and respond differently depending on the users responses

Background: Waiter already offered user a drink
  Given a drinking_conversation exists with topic: "drinking", with: "thirsty@gmail.com"
  And no emails have been sent

Scenario: I move the conversation along
  When I move the drinking_conversation along
  Then "thirsty@gmail.com" should be notified with "Would you like a drink?" via email
  And the drinking_conversation should have the state: "offered_drink"
  And that drinking_conversation should not be finished

Scenario: User replies with yes
  Given the drinking_conversation is offered_drink
  When "thirsty@gmail.com" replies with "yes"
  Then "thirsty@gmail.com" should be notified with "I suggest Beer" via email
  And the drinking_conversation should be finished

Scenario: User replies with no
  Given the drinking_conversation is offered_drink
  When "thirsty@gmail.com" replies with "no"
  Then "thirsty@gmail.com" should be notified with "You've changed" via email
  And the drinking_conversation should be finished

Scenario: User replies something else
  Given the drinking_conversation is offered_drink
  When "thirsty@gmail.com" replies with "piss off"
  Then "thirsty@gmail.com" should be notified with "I suggest Scotch" via email
  And the drinking_conversation should be finished

Scenario: User replies too late
  Given the drinking_conversation is offered_drink
  When "thirsty@gmail.com" replies with "yes"
  Then "thirsty@gmail.com" should not be notified with "I suggest Scotch" via email

