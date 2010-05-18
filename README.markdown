# Conversation

Allows you to have stateful conversations with your users over SMS, email or whatever service you like. For example you could use conversation to accept multi-step commands from users over SMS to perform some task.

## Usage

Conversation is best described using an [example](http://github.com/dwilkie/drinking) about drinking so if your new to Conversation head over there and take a look. If you want to know more about configuring Conversation keep reading...

## Creation

`conversation = Conversation.create(:with => "someone", :topic => "something")`. This will create and return a new instance Conversation with the state: "new", with: "someone" and topic: "something"

The returned value will be an instance of the superclass `Conversation`. `conversation.details` gives you the instance as a `SomethingConversation` provided that `SomethingConversation` is defined in your project and subclasses `Conversation`.

If `SomethingConversation` is not defined or does not subclass `Conversation` `conversation.details` will try and return an instance of `unknown_topic_subclass` which can be set via `Conversation.unknown_topic_subclass = MyUnknownConversation`

If `unknown_topic_subclass` has not been defined then `conversation.details` will return `nil`

Similarly you can create Conversations with no topic: `conversation = Conversation.create(:with => "someone")`. In this case calling `conversation.details` will return an instance of `blank_topic_subclass` (which can be set via `Conversation.blank_topic_subclass = MyBlankConversation`) or `nil` if `blank_topic_subclass` has not been defined

## Finding

### Default

`Conversation.with("someone")` will return all conversations that are not "finished" with "someone" in the last 24 hours.

### Overriding Defaults

`Conversation.converser("someone")` will return all conversations with "someone" regardless of the conversation state or created at time.

`Conversation.in_progress` will return all conversations that are not "finished".

`Conversation.recent` will return all conversations in the last 24 hours.

`Conversation.with("someone")` is just a shortcut for `Conversation.converser("someone").in_progress.recent`

Just like with `create` or `new` the returned conversations will be an instances of the superclass `Conversation`. Use `conversation.details` on each member to get the specific type of Conversation

`Conversation.find_or_create_with("someone", "something")` will return an instance of the most recent conversation with "someone" that is not "finished" within the last 24hrs as a `SomethingConversation`.

If no conversation is found with these conditions `Conversation.find_or_create_with("someone", "something")` will create and return a new instance of `SomethingConversation` provided `SomethingConversation` is defined in the project, subclasses Conversation and is not excluded (see exclusion further down). If `SomethingConversation` does not meet these conditions then `Conversation.find_or_create_with("someone", "something")` will try and return an instance of `unknown_topic_subclass`. If `unknown_topic_subclass` is also undefined then `Conversation.find_or_create_with("someone", "something")` will raise an exception.

## Configuration

Configuration can be done in the conversation initializer in the config/initializers directory.

### Define finishing keywords

`Conversation.finishing_keywords = ["stop", "cancel", "end", "whatever"]`
Now when you call `super("cancel")` in your `move_along!` method in your Conversation subclass it will change the conversations state to "finished"

### Define an unknown topic subclass

`Conversation.unknown_topic_subclass = UnknownTopicConversation`
Now when you call `Conversation.find_or_create_with("someone", "something")` and `SomethingConversation` has not been defined you'll get an instance of `UnknownTopicConversation` instead of an exception.

### Define a blank topic subclass

`Conversation.blank_topic_subclass = BlankTopicConversation`
Now when you call `Conversation.find_or_create_with("someone")` you'll get an instance of `BlankTopicConversation` instead of an exception.

### Define exclusion classes

<pre>
Conversation.exclude AbstractConversation
Conversation.exclude "abstract_conversation"
Conversation.exclude /abstract/
Conversation.exclude :abstract_conversation
Conversation.exclude [InternalConversation, /abstract/]
</pre>

Any of these will ignore `AbstractConversation` when finding Conversations.
So if you have a class defined as `AbstractConversation < Conversation` when you call `Conversation.find_or_create_with("someone", "abstract")` you'll either get an error or an instance of `unknown_topic_conversation` if it is defined. Also, `Conversation.new(:topic => "abstract", :with => "someone").details` will return an instance of `unknown_topic_conversation` if it's defined or `nil` if it's not. This can be useful if you are defining conversations that you never want to work with directly.

## Installation

Add the following to your Gemfile: `gem "conversation"`

## Setup

`rails g conversation:skeleton`
This will generate a migration file and an initializer under `config/initializers/conversation.rb`. It will also create a empty `conversations` folder under your `app/` directory so you can keep your conversations away from your models.

## Notes

Conversation is no longer compatible with Rails 2.3.x
To use with Rails 2.3.x you must install version 0.1.0

Copyright (c) 2010 David Wilkie, released under the MIT license
