Given /^(an|\d+) hours? (?:has|have) elapsed since #{capture_model} was last updated$/ do |time, conversation|
  conversation = model!(conversation)
  time = parse_email_count(time)
  Conversation.record_timestamps = false
  conversation.updated_at = time.hours.ago
  conversation.save!
  Conversation.record_timestamps = true
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

Given /^I configured Conversation with the following: (.+)$/ do |configuration|
  instance_eval(configuration)
end

When /^I start a new conversation(?: with #{capture_fields})?$/ do |fields|
  
end

When /^I call find_or_create_with\("([^\"]*)", "([^\"]*)"\)$/ do |with, topic|
  Conversation.find_or_create_with(with, topic)
end

When /^I start up a conversation with an? (blank|unknown) topic$/ do |template_type|
  topic = ""
  topic = "unknown" if template_type == "unknown"
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

Then /^#{capture_model} details should (?:be|have) (?:an? )?#{capture_predicate}$/ do |name, predicate|
  model!(name).details.should send("be_#{predicate.gsub(' ', '_')}")
end

Then /^conversation\.details\(:include_all => true\) should be a SampleConversation$/ do
  model!("conversation").details(:include_all => true).class.should == SampleConversation
end

