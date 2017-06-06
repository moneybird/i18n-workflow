# frozen_string_literal: true

module I18n
  module Workflow
    module NeverRaiseI18nException
      def translate(key, options = {})
        super(key, options.merge(raise: false))
      end
    end
  end
end

ActionView::Helpers::TranslationHelper.prepend(I18n::Workflow::NeverRaiseI18nException) if defined?(ActionView)
