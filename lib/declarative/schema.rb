require "declarative"
require "declarative/definitions"
require "declarative/defaults"

module Declarative
  # Include this to maintain inheritable, nested schemas with ::defaults and
  # ::feature the way we have it in Representable, Reform, and Disposable.
  #
  # The schema with its defnitions will be kept in ::definitions.
  #
  # Requirements to includer: ::default_nested_class, override building with ::nested_builder.
  module Schema
    def self.extended(extender)
      extender.extend DSL                 # ::property
      extender.extend Feature             # ::feature
      extender.extend Heritage::DSL       # ::heritage
      extender.extend Heritage::Inherited # ::included
    end

    module DSL
      def property(name, options={}, &block)
        heritage.record(:property, name, options, &block)

        default_options = {}
        default_options[:_base]           = default_nested_class
        default_options[:_defaults]       = _defaults
        default_options[:_nested_builder] = nested_builder if block

        definitions.add(name, default_options.merge(options), &block)
      end

      def defaults(options={}, &block)
        heritage.record(:defaults, options, &block)

        _defaults.merge!(options, &block)
      end

      def definitions
        @definitions ||= Definitions.new(definition_class)
      end

      def definition_class # TODO: test me.
        Definitions::Definition
      end

    private
      def _defaults
        @defaults ||= Declarative::Defaults.new
      end

      def nested_builder
        NestedBuilder # default implementation.
      end

      NestedBuilder = ->(options) do
        base = Class.new(options[:_base]) do
          feature *options[:_features]
          class_eval(&options[:_block])
        end
      end
    end

    module Feature
      # features are registered as defaults using _features, which in turn get translated to
      # Class.new... { feature mod } which makes it recursive in nested schemas.
      def feature(*mods)
        mods.each do |mod|
          include mod
          register_feature(mod)
        end
      end

    private
      def register_feature(mod)
        heritage.record(:register_feature, mod) # this is only for inheritance between decorators and modules!!! ("horizontal and vertical")

        defaults[:_features] ||= []
        defaults[:_features] << mod
      end
    end
  end
end
