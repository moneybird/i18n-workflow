require 'rspec'
require 'i18n/workflow'

I18n.load_path = Dir["spec/fixtures/*.yml"]
I18n.backend.reload!
I18n.default_locale = :en

I18n.backend.class.send(:include, I18n::Backend::Cascade)
I18n.backend.class.send(:include, I18n::Workflow::ExplicitScopeKey)
I18n.backend.class.send(:include, I18n::Workflow::AlwaysCascade)
