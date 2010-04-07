Chatterbox::Publishers.register do |notice|
  Chatterbox::Services::Email.deliver(notice)
end

Chatterbox::Services::Email.configure({
      :from => "someone@example.com",
    })

