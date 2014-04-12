require 'spec_helper'
require 'i18n/workflow'

describe I18n::Workflow::ExceptionHandler do

  let(:exception) { I18n::MissingTranslation.new(:nl, "foo.bar.test", {}) }
  let(:file) { double(:file, close: true) }

  before do
    I18n.backend.reload!
    @old_load_path = I18n.load_path
    I18n.load_path = Dir["spec/fixtures/locales/*.yml"]
  end

  after do
    I18n.backend.reload!
    I18n.load_path = @old_load_path
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

    allow(File).to receive(:exists?).with("config/missing_translations.yml").and_return(true)
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
    expect(file).to receive(:write).with("--- \nnl: \n  missing_scope: \n    foobar: \"\"\n    key_scope: \n      foobar: \"\"\n      new_translation: \"\"\n      translation: \"\"\n  translation: \"\"\n")

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
    expect(subject.missing_translations_to_yaml).to eq("--- \nnl: \n  missing_scope: \n    foobar: \"\"\n    key_scope: \n      foobar: \"\"\n      translation: \"\"\n  translation: \"\"\n")
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

end
