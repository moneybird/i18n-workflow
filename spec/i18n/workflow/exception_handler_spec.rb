require 'spec_helper'

describe I18n::Workflow::ExceptionHandler do

  let(:exception) { I18n::MissingTranslation.new(:nl, "foo.bar.test", {}) }
  let(:file) { double(:file, close: true) }

  before do
    I18n.locale = :nl
  end

  it "returns a nicely formatted HTML span" do
    expect(subject.call(exception, :nl, "documents.new.new", { address: "foobar" })).to eq("New foobar")
  end

  it "stores missing translations" do
    subject.call(exception, :nl, "missing.key.new_translation", {})
    expect(subject.missing_translations).to eq([[:nl, :missing_scope, :key_scope, :new_translation]])
  end

  it "writes missing translations to disk" do
    allow(subject).to receive(:missing_translations?).and_return(true)
    allow(subject).to receive(:missing_translations_to_hash).and_return(
      { nl: { missing_scope: { key_scope: { new_translation: "" } } } }
    )

    allow(File).to receive(:exist?).with("config/missing_translations.yml").and_return(true)
    expect(YAML).to receive(:load_file).with("config/missing_translations.yml").and_return({
      nl: {
        missing_scope: {
          key_scope: {
            translation: "",
            foobar: ""
          },
          foobar: ""
        },
        translation: ""
      }
    }.deep_stringify_keys)


    allow(File).to receive(:open).with("config/missing_translations.yml", "w+").and_return(file)
    expect(file).to receive(:write).with("---\nnl:\n  missing_scope:\n    foobar: \'\'\n    key_scope:\n      foobar: \'\'\n      new_translation: \'\'\n      translation: \'\'\n  translation: \'\'\n")

    subject.store_missing_translations
  end

  it "returns a hash with missing translations" do
    allow(subject).to receive(:missing_translations).and_return([
      [:nl, :missing_scope, :key_scope, :translation],
      [:nl, :missing_scope, :key_scope, :foobar],
      [:nl, :missing_scope, :foobar],
      [:nl, :translation]
    ])
    expect(subject.missing_translations_to_hash).to eq(
      {
        nl: {
          missing_scope: {
            key_scope: {
              translation: "",
              foobar: ""
            },
            foobar: ""
          },
          translation: ""
        }
      }
    )
  end

  it "returns a yaml with the missing translations" do
    allow(subject).to receive(:missing_translations).and_return([
      [:nl, :missing_scope, :key_scope, :translation],
      [:nl, :missing_scope, :key_scope, :foobar],
      [:nl, :missing_scope, :foobar],
      [:nl, :translation]
    ])
    expect(subject.missing_translations_to_yaml).to eq("---\nnl:\n  missing_scope:\n    key_scope:\n      translation: \'\'\n      foobar: \'\'\n    foobar: \'\'\n  translation: \'\'\n")
  end

  it "integrates with I18n.t nicely" do
    I18n.exception_handler = subject
    I18n.default_locale = "nl"
    I18n.t("some_missing_translation", scope: ["foobar", "test"])

    expect(subject.missing_translations).to eq([
      [:nl, :foobar_scope, :test_scope, :some_missing_translation]
    ])

    subject.clear_missing_translations
  end

  it "duplicates the missing translations to multiple locales" do
    allow(subject).to receive(:missing_translations?).and_return(true)
    allow(subject).to receive(:missing_translations_to_hash).and_return(
      { nl: { missing_scope: { key_scope: { new_translation: "" } } } }
    )

    allow(File).to receive(:exist?).with("config/missing_translations.yml").and_return(true)
    expect(YAML).to receive(:load_file).with("config/missing_translations.yml").and_return({
      nl: {
        missing_scope: {
          key_scope: {
            translation: "",
            foobar: ""
          },
          foobar: ""
        },
        translation: ""
      }
    }.deep_stringify_keys)


    allow(File).to receive(:open).with("config/missing_translations.yml", "w+").and_return(file)
    expect(file).to receive(:write).with("---\nnl:\n  missing_scope:\n    foobar: \'\'\n    key_scope:\n      foobar: \'\'\n      new_translation: \'\'\n      translation: \'\'\n  translation: \'\'\nen:\n  missing_scope:\n    foobar: \'\'\n    key_scope:\n      foobar: \'\'\n      new_translation: \'\'\n      translation: \'\'\n  translation: \'\'\n")

    subject.store_missing_translations(duplicate_to_locales: [:en])
  end

  it 'does not overwrite existing translations in multiple locales' do 
    allow(subject).to receive(:missing_translations?).and_return(true)
    allow(subject).to receive(:missing_translations_to_hash).and_return(
      { nl: { translation_key_two: "" } }
    )

    allow(File).to receive(:exist?).with("config/missing_translations.yml").and_return(true)
    expect(YAML).to receive(:load_file).with("config/missing_translations.yml").and_return({
      nl: { translation_key_one: "A Dutch translation" },
      en: { translation_key_one: "An English translation" }
    }.deep_stringify_keys)

    allow(File).to receive(:open).with("config/missing_translations.yml", "w+").and_return(file)
    expect(file).to receive(:write).with("---\nnl:\n  translation_key_one: A Dutch translation\n  translation_key_two: \'\'\nen:\n  translation_key_one: An English translation\n  translation_key_two: \'\'\n")

    subject.store_missing_translations(duplicate_to_locales: [:en])
  end

  it 'works nicely with nested existing translations in multiple locales' do 
    allow(subject).to receive(:missing_translations?).and_return(true)
    allow(subject).to receive(:missing_translations_to_hash).and_return(
      { nl: { translation_scope: { translation_key_two: "" } } }
    )

    allow(File).to receive(:exist?).with("config/missing_translations.yml").and_return(true)
    expect(YAML).to receive(:load_file).with("config/missing_translations.yml").and_return({
      nl: { translation_key_one: "A Dutch translation" },
      en: { translation_key_one: "An English translation" }
    }.deep_stringify_keys)

    allow(File).to receive(:open).with("config/missing_translations.yml", "w+").and_return(file)
    expect(file).to receive(:write).with("---\nnl:\n  translation_key_one: A Dutch translation\n  translation_scope:\n    translation_key_two: \'\'\nen:\n  translation_key_one: An English translation\n  translation_scope:\n    translation_key_two: \'\'\n")

    subject.store_missing_translations(duplicate_to_locales: [:en])
  end

  it 'works with deeply nested existing translations in multiple locales' do \
    allow(subject).to receive(:missing_translations?).and_return(true)
    allow(subject).to receive(:missing_translations_to_hash).and_return(
      { nl: { translation_scope_two: { foo: "" , translation_scope_three: { bar: "" }} } }
    )

    allow(File).to receive(:exist?).with("config/missing_translations.yml").and_return(true)
    expect(YAML).to receive(:load_file).with("config/missing_translations.yml").and_return({
      nl: { translation_key_one: "A Dutch translation", translation_scope_two: { translation_key_two: "Dutch translation 2", translation_scope_three: { translation_key_three: "Dutch translation 3" } } },
      en: { translation_key_one: "An English translation", translation_scope_two: { translation_key_two: "English translation 2", translation_scope_three: { translation_key_three: "English translation 3" } } }
    }.deep_stringify_keys)

    allow(File).to receive(:open).with("config/missing_translations.yml", "w+").and_return(file)
    expect(file).to receive(:write).with("---\nnl:\n  translation_key_one: A Dutch translation\n  translation_scope_two:\n    foo: \'\'\n    translation_key_two: Dutch translation 2\n    translation_scope_three:\n      bar: \'\'\n      translation_key_three: Dutch translation 3\nen:\n  translation_key_one: An English translation\n  translation_scope_two:\n    foo: \'\'\n    translation_key_two: English translation 2\n    translation_scope_three:\n      bar: \'\'\n      translation_key_three: English translation 3\n")

    subject.store_missing_translations(duplicate_to_locales: [:en])
  end
end
