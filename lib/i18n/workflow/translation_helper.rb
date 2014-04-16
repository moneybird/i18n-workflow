if defined?(ActionView)
  module ActionView
    module Helpers
      module TranslationHelper

        def translate_with_rescue_format(key, options = {})
          translate_without_rescue_format(key, options.merge(rescue_format: true))
        end

        def t(key, options = {})
          translate_without_rescue_format(key, options.merge(rescue_format: true))
        end

        alias_method_chain :translate, :rescue_format
      end
    end
  end unless ActionView::Helpers::TranslationHelper.respond_to?(:translate_with_rescue_format)
end
