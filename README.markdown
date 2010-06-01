# Conversational

Conversational makes it easier to accept incoming text messages (SMS) and respond to them in your application. You could also use Conversational to respond to incoming email or IM.

Conversational allows you to have have *stateful* or *stateless* interactions with your users.

## Stateless Conversations

This is the most common way of dealing with incoming messages in SMS apps. Stateless conversations don't know anything about a previous request and therefore require you to text in an explicit command. Let's look at an example:

Say you have an application which allows you to interact with Facebook over SMS. You want be able to write on on your friends wall and change your status by sending an SMS to your app. You also want to receive SMS alerts when a friend writes on your wall or you have a new friend request.

Let's tackle the incoming messages first.

### Incoming Text Messages

Say your commands are:

*  us is ready for a beer
*  wow johnny wanna go 4 a beer?

Where "us" is update status and "wow" is write on wall

Assuming you have set up a controller in your application to accept the incoming text messages when they are posted from your SMS gateway you could use Conversational as follows:

    class Conversation
      include Conversational::Conversation
      converse do |with, message|
        OutgoingTextMessage.send(with, message)
      end
    end

    class UsConversation < Conversation
      def move_along(message)
        # code to update status
        say "Successfully updated your status"
      end
    end

    class WowConversation < Conversation
      def move_along(message)
        # Code to write on wall
        say "Successfully wrote on wall"
      end
    end

    class IncomingTextMessageController
      def create
        message = params[:message]
        topic = params[:message].split(" ").first
        number = params[:number]
        Conversation.new(:with => number, :topic => topic).details.move_along(message)
      end
    end

There's quite a bit going on here so let's have a bit more of a look.

In the controller a new Conversation is created with the number of the incoming message and the topic as the first word of the text message. In our case the topic will be either "us" or "wow". Calling `details` on an instance of Conversation will try and return an instance of a class in your project that subclasses your main Conversation class and has the same name as the topic. In our case our main Conversation class *is* called Conversation so a topic of "us" will map to `UsConversation`. Similarly "wow" maps to `WowConversation`. So say we text in "us is ready for a beer" an instance of `UsConversation` is returned and move_along is then called on the instance.

Inside our subclassed conversations there is a method available to us called `say`. Say simple executes the converse block you set up inside your main Conversation class.In our case this will call `OutgoingTextMessage.send` passing in the number and the message. Obviously this example doesn't contain any error checking. If we text in something starting with other than "us" or "wow" we'll get an error because `details` will return nil and `move_along` will be called on `nil`

### Outgoing Text Messages

To handle your Facebook alerts you can simply make use of Conversation's `say` method: You might do something like this:

    class FacebookAlert < Conversation
      def wrote_on_wall(facebook_notification)
        # Code to get the wall details
        say "Someone wrote on your wall..."
      end

      def friend_request(facebook_notification)
        # Code to get the name of the person who befriended you
        say "You have a new friend request from ..."
      end
    end

Then when you get a facebook alert simply do either:
    
    FacebookAlert.new(:with => "your number").wrote_on_wall(facebook_notification)
    FacebookAlert.new(:with => "your number").friend_request(facebook_notification)

## Stateful Conversations

Conversational also allows you to have *stateful* conversations. A stateful conversation knows about prevous interactions and therefore allows you to respond differently. Note this is currently only supported in Rails.

Let's build on the prevous example using stateful conversations.

Our application so far is *stateless*. Currently if we get a friend request we have no way of accepting or rejecting it. If we were to continue building a stateless application we would simple add a couple of new commands such as:

* "afr &lt;friend&gt;"
* "rfr &lt;friend&gt;"
where "afr" is accept friend request and "rfr" is reject friend request.

But instead of doing that let's allow us to respond to a friend request notification with yes or no.

So we'll change our existing friend request alert to: "You have a new friend request from Johnnie Cash. Do you want to accept? Text yes or no."

With the current stateless implementation if they text "yes" then `details` will look to see if `YesConversation` is defined in our project, won't be able to find and return `nil` So here's how to make our application stateful.

    class Conversation < ActiveRecord::Base
      include Conversational::Conversation
      converse do |with, message|
        OutgoingTextMessage.send(with, message)
      end
      protected
        def finish
          state = "finished"
          self.save!
        end
    end

    class IncomingTextMessageController
      def create
        message = params[:message]
        topic = params[:message].split(" ").first
        number = params[:number]
        Conversation.find_or_create_with(number, topic).move_along(message)
      end
    end

    class FacebookAlertConversation < Conversation
      def move_along(message)
        if message == "yes"
          # code to accept friend request
          say "You successfully accepted the friend request"
        elsif message == "no"
          # say "You successfully rejected the friend request"
        else
          say "Invalid response. Reply with yes or no"
        end
        finish
      end

      def friend_request(facebook_notification)
        # Code to get the name of the person who befriended you
        say "You have a new friend request from ...Do you want to accept? Text yes or no."
      end
    end

The first change you'll notice is that our Conversation base class now extends from ActiveRecord::Base. This does a couple of things. But first we will need a migration file (which can be generated with `rails g conversational:migration`). Once we have that we can simply migrate our database `rake db:migrate`. Extending from ActiveRecord::Base adds a couple of methods for us which i'll describe in some more detail later. For our example we only care about one of them.

Jumping over to our controller you can see that now we are calling `Conversation.find_or_create_with` This method was added when we extended Conversation from ActiveRecord::Base. The method tries to return the last *recent*, *open* conversation with this number. By *open* we mean that it's state is *not* finished and by *recent* we mean that it was updated within the last 24 hours. More on how you can override this later. If it finds one it will return an instance of this conversation subclass. If it doesn't it will create a new conversation with the topic specified and return it as an instance of its subclass (just like `details`).

Now take a look at our `FacebookAlert` class. The first thing is that we renamed it to `FacebookAlertConversation`. This is important so that it is now recognised as a type of conversation.

There is also a new method `move_along` which looks at the message to see if the user replied with "yes" or "no" and responds appropriately. Notice it also calls `finish`. 

If we jump back and take a look at our main Conversation class we see that `finish` marks the conversation state as finished so it will be found by `find_or_create_with` It is important that you remember to call `finish` on all conversations where you don't expect a response.

So how does this all tie together?

The application receives an alert from Facebook with a new friend request and calls:

    FacebookAlert.create!(
      :with => "your number", :topic => "facebook_alert"
    ).friend_request(facebook_notification)

This sends the following message to you: "You have a new friend request from...Do you want to accept? Text yes or no."

Notice that it calls `create!` and *not* `new` as we want to save this conversation. Also notice that topic is set to "facebook_alert" which is the name of the class minus "Conversation". This is important so `find_or_create_with` can find the conversation. Also notice that `friend_request` does *not* call finish. This conversation isn't over yet!

Now sometime later you reply with "yes". The controller calls
`Conversation.find_or_create_with` which finds your open conversation and returns the an instance as a `FacebookAlertConversation`

The controller then calls `move_along` on this conversation which looks at your message, sees that you replied with "yes" and replies with "You successfully accepted the friend request". It also calls `finish` which marks the conversation as finished, so that next time you text something in it won't find any open conversations.

There are still a few more things we need to do in order to make this application work properly. Right now if we text in something other than "us", "wow" or "yes" we will get an exception. Let's fix it in the following section

## Configuration

In our example application we are responding to requests based on the first word of their text message. But what if they text in something unknown to us or they text in something blank?

You can configure Conversation to deal with this situation as follows:

    class Conversation
      unknown_topic_subclass = UnknownTopicNotification
      blank_topic_subclass = BlankTopicNotification
    end

    class UnknownTopicNotification < Conversation
      def move_along
        say "Sorry. Unknown Command"
      end
    end

    class BlankTopicNotification < Conversation
      def move_along
        say "Hey. What do you want?"
      end
    end

Now when the user texts in with "hey jonnie", `details` will try and find a conversation defined as `HeyConversation`, won't be able to find it and will return an instance of `UnknownTopicConversation`

`move_along` then causes a message to be sent saying "Sorry. Unknown Command."

The same thing happens for a blank conversation.

There is one more subtle issue with our application. What if a user texts in "facebook_alert"? The reply will be: "Invalid response. Reply with yes or no" when it should be "Sorry. Unknown Command". This is because if `find_or_create_with` cannot find an existing conversation it will try and create one with the topic "facebook_alert" if `FacebookAlertConversation` is defined in our application (which it is). To solve this prolem we can use `exclude`

    class Conversation
      exclude FacebookAlertConversation
    end

## Overriding Defaults

When you extend your base conversation class from ActiveRecord::Base in addition to `find_or_create_with` you will also get the following class methods:

`converser("someone")` returns all conversations with "someone"

`in_progress` returns all conversations that are not "finished".

`recent(time)` returns all conversations in the last *time* or within the last 24 if *time* is not suppied

`with("someone")` a convienience method for `converse("someone").in_progress.recent`


## Installation

Add the following to your Gemfile: `gem "conversational"`

## Setup

`rails g conversational:skeleton`
Generates a base conversation class under app/conversations

`rails g conversational:migration`
Generates a migration file if you want to use Conversational with Rails

## More Examples

Here's an [example](http://github.com/dwilkie/drinking) *stateful* conversation app  about drinking

## Notes

Conversational is compatible with Rails 3
To use with Rails 2.3.x you must install Conversation version 0.1.0 which is an old and obsolete version.

Copyright (c) 2010 David Wilkie, released under the MIT license
