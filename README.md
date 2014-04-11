# I18n::Workflow

This gem contains a workflow for I18n in Rails projects. I18n is a
great tool for translating an application, but the workflow might get
tedious when working with larger applications and managing a lot of
translations. The workflow in this gem builds upon the basics of I18n
and extends it to make translating easier.

## Installation

Add this line to your application's Gemfile:

    gem 'i18n-workflow'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install i18n-workflow

## Usage

### Conventions

This workflow is centered around a few conventions to make translating easier:

1. All locales are stored in `config/locales`.
2. There is one locale file for each language. The locales are stored in YAML.
3. To prevent overlaps in keys and scopes, each scope is appended by `_scope`:

  ```YAML
  ---
  en:
    invoices: "Invoices"
    invoices_scope:
      invoice_id: Invoice ID
  ```

4. Lookup of translations always cascades, allowing for reuse of keys but also fine grained
  scoping if necessary.
5. During development and testing, a special missing_translations.yml file collects all
  missing translations. Translations are done in this file and merged with the master
  locale file to ensure the right sorting and scoping.
6. Editing and removing of translations is still done in the master files in `config/locales`

### ExceptionHandler

After loading the gem and developing your application, a file `config/missing_translations.yml`
is created. This file contains all missing keys that are encountered when running code.
The keys are collected by the custom exception handler `I18n::Workflow::ExceptionHandler`.

When new keys need to be translated, the translation can be done in the `missing_translations.yml`
file. By calling `bin/merge_missing_translations` the missing translations are merged into
the locale files. Any keys that are kept untranslated are not copied, all keys are automatically
sorted.

Usage:

```ruby
# Install the exception handler in I18n.
# You probably want to skip collecting missing translations in production
I18n.exception_handler = I18n::Workflow::ExceptionHandler.new unless Rails.env.production?
```

Furthermore you should call `store_missing_translations` to write the missing translations to disk.

```ruby
# After each request, write all missing translations to disk
class ApplicationController < ActionController::Base
  after_filter do
    I18n.exception_handler.store_missing_translations unless Rails.env.production?
  end
end

# After running specs, write all missing translations to disk
RSpec.configure do |config|
  config.after(:suite) do
    I18n.exception_handler.store_missing_translations
  end
end
```

### Explicit scoping

Although our convention states that each scope should have "_scope" appended, we
still want to use conventional lookup of translations in scopes. The workflow
allows you to write `I18n.t("key", scope: [:invoices])` and still get the result
for the `invoices_scope`. This is done by extending the backend of I18n:

```ruby
I18n.backend.class.send(:include, I18n::Workflow::ExplicitScopeKey)
```

A caveat of this approach is that some Rails helpers use the functionality of
I18n to retreive a hash with translations instead of one string value. For example:

```ruby
# Rails uses this method to retreive a hash with options for number_to_currency
I18n.t("number.currency.format")
```

In YAML, the `format` scope should not get the "_scope" extension, because it is used
as a key instead of a scope:

```YAML
---
nl:
  number_scope:
    currency_scope:
      format:
        delimiter: "."
        format: "%u %n"
        negative_format: "%u-%n"
        precision: 2
        separator: ","
        unit: €
```

This caveat is only applicable to a small list of Rails helpers. In our experience
we never use the method of retreiving a hash from I18n in our application, therefor
we find it acceptable to have to work around this issue.

### Always cascade

By default, I18n will not cascade to a parent scope if the key is not found
in the given scope. It is possible to use the `cascade: true` option for every
call to `I18n.translate`. By including `I18n::Workflow::AlwaysCascade`, cascading
will be default for I18n.

```ruby
I18n.backend.class.send(:include, I18n::Workflow::AlwaysCascade)
```

This approach has also a great advantage when using automatic Rails view scoping:
`t(".show")`. By default the lookup of this translation will start in
`controller_scope.template_scope.show`, but will cascade down to the highest level
to attain perfect reusability of code whilest still allowing a more detailed
translation for a view when needed.

### Check missing translations

In a development environment, it is advisable to add translations for keys as soon
as possible. The `bin/check_missing_translations` script checks the contents of
`config/missing_translations.yml` and will print an error when the file is not empty.
The script will return a proper exit code based on the outcome, making the script
very usable in continuous integration.
