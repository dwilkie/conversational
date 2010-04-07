Given /^I configured my (blank|unknown) conversation topic template as (\w+)$/ do |template_type, template_name|
  Conversation.send("#{template_type}_topic_subclass=", template_name.constantize)
end

When /^I start up a conversation with a (blank|unknown) topic$/ do |template_type|
  topic = ""
  topic = "ihopethisisunknown" if template_type == "unknown"
  Given "a conversation exists with topic: \"#{topic}\", with: \"someone\""
end

