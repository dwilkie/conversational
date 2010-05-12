require "conversation"
require "rails"
module Conversation
  require 'conversation/engine' if defined?(Rails)
  class Engine < Rails::Engine
    engine_name :conversation
  end
end

