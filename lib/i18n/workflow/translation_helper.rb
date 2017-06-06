# frozen_string_literal: true

module NeverRaiseI18nException
  def translate(key, options = {})
    super(key, options.merge(raise: false))
  end
end

ActionView::Helpers::TranslationHelper.prepend(NeverRaiseI18nException) if defined?(ActionView)
