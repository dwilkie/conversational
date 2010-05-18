# Uncomment the following to configure Conversation to use Mail
#Conversation.converse do |with, notice|
#  Mail.deliver do
#    to with
#    from "someone@example.com"
#    subject notice
#    body notice
#  end
#end

# Or you can use Conversation with whatever you like
# Conversation.converse do |with, notice|
#   SMSWorker.send(:number => with, :message => notice)
# end

# Configure finishing keywords
# Conversation.finishing_keywords = ["cancel"]

# Configure Unknown Topic Subclass
# Conversation.unknown_topic_subclass = UnknownTopicConversation

# Configure Blank Topic Subclass
# Conversation.blank_topic_subclass = BlankTopicConversation

# Configure exclusion Conversations
# Any of these will prevent Conversation.find_or_create_with or conversation.details
# from returning an instance of AbstractConversation. You can supply a Class, String, Symbol, Regexp or an array including any of these combinations.

# Conversation.exclude AbstractConversation
# Conversation.exclude "abstract_conversation"
# Conversation.exclude /abstract/
# Conversation.exclude :abstract_conversation
# Conversation.exclude [InternalConversation, /abstract/]

