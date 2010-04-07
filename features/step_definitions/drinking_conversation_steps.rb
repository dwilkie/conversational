When /^"([^\"]*)" replies with "([^\"]*)"$/ do |with, summary|
  # Rails 3 => Conversation.with(with).last
  conversation = Conversation.converser(with).in_progress.recent.last
  conversation.details.move_along!(summary) if conversation
end

Then /^"([^\"]*)" should (not )?be notified with "([^\"]*)" via (\w+)/ do |to, notify, summary, via|
  if via == "email"
    unless notify =~ /not/
      Then "\"#{to}\" should receive an email with subject \"#{summary}\""
    else
      Then "\"#{to}\" should receive no emails with subject \"#{summary}\""
    end
  end
end

Then /^#{capture_model} should have the state: "([^\"]*)"$/ do |name, state|
  model!(name).state.should == state
end

