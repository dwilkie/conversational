module Conversational
  class ConversationDefinition
    cattr_accessor :unknown_topic_subclass
    cattr_accessor :blank_topic_subclass
    cattr_accessor :notification
    cattr_writer   :klass

    def self.exclude(classes)
      if classes
        if classes.is_a?(Array)
          classes.each do |class_name|
            check_exclude_options!(class_name)
          end
        else
          check_exclude_options!(classes)
        end
      end
      @@excluded_classes = classes
    end

    def self.find_subclass_by_topic(topic, options = {})
      subclass = nil
      if topic.nil? || topic.blank?
        unless options[:exclude_blank_unknown]
          subclass = blank_topic_subclass if blank_topic_subclass
        end
      else
        project_class_name = self.topic_subclass_name(topic)
        begin
          project_class = project_class_name.constantize
        rescue
          project_class = nil
        end
        # the subclass has been defined
        # check that it is a subclass klass
        if project_class && project_class <= @@klass &&
          (options[:include_all] || !self.exclude?(project_class))
            subclass = project_class
        else
          unless options[:exclude_blank_unknown]
            subclass = unknown_topic_subclass if unknown_topic_subclass
          end
        end
      end
      subclass
    end

    def self.topic_defined?(topic)
      self.find_subclass_by_topic(
        topic,
        :exclude_blank_unknown => true
      )
    end

    def self.topic_subclass_name(topic)
      topic.classify + @@klass.to_s
    end

    private
      def self.exclude?(subclass)
        if defined?(@@excluded_classes)
          if @@excluded_classes.is_a?(Array)
            @@excluded_classes.each do |excluded_class|
              break if exclude_class?(subclass)
            end
          else
            exclude_class?(subclass)
          end
        end
      end

      def self.exclude_class?(subclass)
        if @@excluded_classes.is_a?(Class)
          @@excluded_classes == subclass
        elsif @@excluded_classes.is_a?(Regexp)
          subclass.to_s =~ @@excluded_classes
        else
          excluded_class = @@excluded_classes.to_s
          begin
            excluded_class.classify.constantize == subclass
          rescue
            false
          end
        end
      end

      def self.check_exclude_options!(classes)
        raise(
          ArgumentError,
          "You must specify an Array, Symbol, Regex, String or Class or nil. You specified a #{classes.class}"
        ) unless classes.is_a?(Symbol) ||
            classes.is_a?(Regexp) ||
            classes.is_a?(String) ||
            classes.is_a?(Class)
      end
  end
end

