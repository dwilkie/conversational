class SampleConversation < Conversation
  def move_along!(message=nil)
    say "something"
    super(message)
  end
end

