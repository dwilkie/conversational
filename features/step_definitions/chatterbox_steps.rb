Given /^the user has configured Chatterbox to use the Chatterbox email service$/ do
# assume user has this already configured otherwise you will get 2 emails
#  Chatterbox::Publishers.register do |notice|
#    Chatterbox::Services::Email.deliver(notice)
#  end
  Chatterbox::Services::Email.configure({
        :from => "jane@example.com",
      })
end

Given /^the user has configured Conversation to use the Chatterbox email service$/ do
  Conversation.converse do |with, notice|
    Chatterbox.notify(:summary => notice) do |via|
      via["Chatterbox::Services::Email"] = {:to => with}
    end
  end
end

When /^a notification is sent from Conversation$/ do
  Given "a sample_conversation exists with topic: \"sample\", with: \"sample@example.com\""
  model("sample_conversation").move_along!
end

Then /^the Chatterbox email service should be used to deliver it$/ do
  Then "\"sample@example.com\" should receive an email"
end

