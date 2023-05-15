# frozen_string_literal: true

# Module to add a _scope to each scope
module I18n
  module Workflow
    module ExplicitScopeKey
      def lookup(locale, key, scope = [], options = {})
        scope = I18n.normalize_keys(nil, key, scope, options[:separator] || I18n.default_separator)
        scope = scope[1..] if scope.first.nil?
        key = scope.pop
        scope = scope.map { |s| "#{s}_scope".to_sym }
        options.merge!(cascade: true)
        super(locale, key, scope, options)
      end
    end
  end
end
