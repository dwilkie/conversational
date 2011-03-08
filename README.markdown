# Conversational

NOTE: Conversational no longer supports ActiveRecord additions or "stateful" conversations. If you still need this feature use version 0.3.2

Conversational makes it easier to accept incoming text messages (SMS), emails and IM and respond to them in your application.

## Installation

`gem install conversational`

## Usage

Let's say you have an application which allows you to interact with Facebook over SMS. You want be able to write on on your friends wall and change your status by sending an SMS to your app. You also want to receive SMS alerts when a friend writes on your wall or you have a new friend request.

Let's tackle the incoming messages first.

### Incoming Text Messages

Let's say your commands are:

*  us is ready for a beer
*  wow johnny wanna go 4 a beer?

Where "us" is update status and "wow" is write on wall

Assuming you have set up a controller in your application to accept incoming text messages you could use Conversational as follows:

    class Conversation
      include Conversational::Conversation
      def say
        # code to send an SMS
      end
    end

    class UsConversation < Conversation
      def process
        # code to update status
        say "Successfully updated your status"
      end
    end

    class WowConversation < Conversation
      def process
        # Code to write on wall
        say "Successfully wrote on wall"
      end
    end

    class IncomingTextMessageController
      def create
        topic = params[:message].split(" ").first
        Conversation.new(:topic => topic).details.process
      end
    end

There's quite a bit going on here so let's have a bit more of a look.

In the controller a new Conversation is created with the topic as the first word of the text message. In this case the topic might be "us" or "wow". Calling `details` on an instance of Conversation will try and return an instance of a class in your project that subclasses the class that includes `Conversational::Conversation` and has the same name as the topic. In this case a topic of "us" will map to `UsConversation` and a topic of "wow" maps to `WowConversation`. Let's say the user texts in "us is ready for a beer". The code will create an instance of `UsConversation` then call `process` on the instance.

There's a problem though, if the user texts in something starting with other than "us" or "wow" we'll get an error because `details` will return `nil` and `process` will be called on `nil`. We'll handle that in the next section.

## Configuration

You can configure Conversation to deal with unknown or blank topics as follows:

    class Conversation
      unknown_topic_subclass(UnknownTopicConversation)
      blank_topic_subclass(BlankTopicConversation)
    end

    class UnknownTopicNotification < Conversation
      def process
        say "Sorry. Unknown Command"
      end
    end

    class BlankTopicNotification < Conversation
      def process
        say "Hey. What do you want?"
      end
    end

Now if the user texts something like "hey jonnie", they'll receive: "Sorry. Unknown Command." Similarly, if they text nothing, they'll receive "Hey. What do you want?"

Copyright (c) 2011 David Wilkie, released under the MIT license

