if defined?(ActionView)
  module ActionView
    module Helpers
      module TranslationHelper

        def translate_with_raise(key, options = {})
          translate_without_raise(key, options.merge(raise: false))
        end

        def t(key, options = {})
          translate_without_raise(key, options.merge(raise: false))
        end

        alias_method_chain :translate, :raise
      end
    end
  end unless ActionView::Helpers::TranslationHelper.respond_to?(:translate_with_raise)
end
