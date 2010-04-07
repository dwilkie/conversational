class ConversationGenerator < Rails::Generator::Base

  def initialize(runtime_args, runtime_options = {})
    super
    @chatterbox = @args.empty? ? false : @args.first
  end

  def manifest
    record do |m|
      m.file 'chatterbox.rb', 'config/initializers/chatterbox.rb' if @chatterbox == "chatterbox"
      m.file 'conversation.rb', 'config/initializers/conversation.rb'
      m.migration_template 'create_conversations.rb', 'db/migrate', :migration_file_name => "create_conversations"
    end
  end
end

