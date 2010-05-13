Given /^(an|\d+) hours? (?:has|have) elapsed since #{capture_model} started$/ do |time, conversation|
  conversation = model!(conversation)
  time = parse_email_count(time)
  conversation.created_at = time.hours.ago
  conversation.save!
end

Given /^#{capture_model} is (.+)$/ do |conversation, state|
  conversation = model!(conversation)
  conversation.state = state
  conversation.save!
end

Given /^no conversations exist with: "([^\"]*)"/ do |with|
  find_models("conversation", "with: \"#{with}\"").each do |instance|
    instance.destroy
  end
end

Given /^I configure Conversation with following finishing keywords: "([^\"]*)"/ do |finishing_strings|
  Conversation.finishing_keywords = finishing_strings.split(", ")
end

Given /^I configured my (blank|unknown) conversation topic template as (\w+)$/ do |template_type, template_name|
  Conversation.send("#{template_type}_topic_subclass=", template_name.constantize)
end

When /^I call find_or_create_with\("([^\"]*)", "([^\"]*)"\)$/ do |with, topic|
  Conversation.find_or_create_with(with, topic)
end

When /^I start up a conversation with a (blank|unknown) topic$/ do |template_type|
  topic = ""
  topic = "ihopethisisunknown" if template_type == "unknown"
  Given "a conversation exists with topic: \"#{topic}\", with: \"someone\""
end

Then /^the conversation details should be a (\w+)$/ do |template_name|
  model!("conversation").details.class.should == template_name.constantize
end

Then /^I should (not )?be able to find a conversation with: "([^\"]*)"$/ do |negative, with|
  conversation = Conversation.with(with).last
  unless negative
    conversation.should == model!("conversation")
  else
   conversation.should be_nil
  end
end

