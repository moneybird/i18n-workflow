require 'spec_helper'

describe I18n::Workflow::ExplicitScopeKey do

  before do
    I18n.locale = :en
  end

  it "appends _scope to the given scopes in a lookup" do
    expect(I18n.t("scoped", scope: [:first, :second])).to eq("Scoped")
  end

end
