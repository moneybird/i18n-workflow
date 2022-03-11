# frozen_string_literal: true

# Module to make cascading in translations the default option
module I18n::Workflow::AlwaysCascade
  def lookup(locale, key, scope = [], options = {})
    options.merge!(cascade: true)
    super(locale, key, scope, options)
  end
end
