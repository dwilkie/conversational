class DrinkingConversation < Conversation
  include AASM
  #############################################################################
  # STATES
  #############################################################################

  aasm_state :offered_drink

  aasm_event :offer_drink do
    transitions :to => :offered_drink, :from => :new
  end

  aasm_event :finish do
    transitions :to => :finished, :from => [:offered_drink]
  end

  def move_along!(message=nil)
    case state

    when "new"
      say "Would you like a drink?"
      offer_drink

    when "offered_drink"
      message ||= ""
      case message.downcase

      when "yes"
        say "I suggest Beer"

      when "no"
        say "You've changed"

      else
        say "I suggest Scotch" unless Conversation.finishing_keywords && Conversation.finishing_keywords.include?(message)
      end
    finish
    end
    super(message)
  end
end

