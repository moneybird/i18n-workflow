# frozen_string_literal: true

require 'active_support/core_ext/object/deep_dup'
require 'active_support/core_ext/hash'
require 'i18n'
require 'yaml'

# This class handles exceptions for I18n. It has the following purpose:
#
# 1. It changes the <span class="translation_missing"> response for MissingTranslations exceptions
#    The result now includes the values of interpolated variables, this allows for easier testing with
#    missing translations
#
# 2. It stores each missing translations in an array and provides methods to inspect
#    the missing translations and store them in config/missing_translations.yml
#
module I18n
  module Workflow
    class ExceptionHandler < I18n::ExceptionHandler

      # Handles exceptions from I18n
      def call(exception, locale, key, options)
        if exception.is_a?(I18n::MissingTranslation)
          keys = I18n.normalize_keys(locale, key, options[:scope])

          locale = keys.shift
          last_key = keys.pop
          keys = [locale] + keys.map { |s| "#{s}_scope".to_sym } + [last_key]

          unless keys.length == 2 and keys.last.nil?
            missing_translations << keys
          end

          interpolations = options.symbolize_keys.except(*(I18n::RESERVED_KEYS + [:rescue_format]))
          keys.last.to_s.tr('_', ' ').capitalize + ' ' + interpolations.values.join(' ')
        else
          super
        end
      end

      # Returns if there are any missing translations
      def missing_translations?
        missing_translations.any?
      end

      # Array with missing translations
      def missing_translations
        @missing_translations ||= []
      end

      # Clears the missing translations
      def clear_missing_translations
        @missing_translations = []
      end

      # Returns a nested hash with missing translations
      def missing_translations_to_hash(locale = nil)
        result_hash = {}
        missing_translations.uniq.each do |key|
          next if locale && key[0] != locale.to_sym
          hash = ''
          key.reverse.each { |key| hash = { key => hash } }
          result_hash = result_hash.deep_merge(hash)
        end
        result_hash
      end

      # Returns a YAML string with the missing translations
      def missing_translations_to_yaml
        missing_translations_to_hash.deep_stringify_keys.to_yaml
      end

      def filter_missing_translations(match_key)
        missing_translations.reject! { |keys| keys.join('.') =~ match_key }
      end

      # Stores the missing translations in config/missing_translations.yml and
      # clears the missing translations. If config/missing_translations.yml exists
      # and contains translations, the new missing translations are merged.
      def store_missing_translations(locale=nil, duplicate_to_locales: [])
        return unless missing_translations?
        missing_translations_path = 'config/missing_translations.yml'

        locale ||= I18n.default_locale

        if File.exist?(missing_translations_path)
          current_missing_translations = YAML.load_file(missing_translations_path)
        end
        current_missing_translations = {} unless current_missing_translations.is_a?(Hash)

        missing_translation_hash = missing_translations_to_hash(locale)
                                    .deep_stringify_keys
                                    .deep_merge(current_missing_translations)
                                    .transform_keys(&:to_s)

        duplicate_to_locales.each do |available_locale|
          available_locale = available_locale.to_s
          source_translations = missing_translation_hash[locale.to_s].deep_dup

          if missing_translation_hash.key?(available_locale)
            # Deep merge only missing keys from source locale
            missing_translation_hash[available_locale].deep_merge!(source_translations) { |_, old_val, new_val|
              old_val.is_a?(Hash) ? old_val : old_val.presence || ""
            }
          else
            # Create new locale with all translations but without original locale values
            missing_translation_hash[available_locale] = source_translations.deep_transform_values { "" }
          end
        end

        missing_translation_hash = missing_translation_hash.transform_values(&proc)

        file = File.open(missing_translations_path, "w+")
        file.write(missing_translation_hash.deep_stringify_keys.to_yaml(line_width: -1))
        file.close

        clear_missing_translations
      end

      def proc 
        proc = Proc.new do |v|
          if v.kind_of?(Hash)
            v.transform_keys(&:to_s).sort_by {|key, _| key.to_s }.to_h.transform_values(&proc)
          else
            v
          end
        end
      end
    end
  end
end
