require 'spec_helper'

describe I18n::Workflow::AlwaysCascade do

  context "makes the I18n lookup always casade to lower scopes" do

    it "lowest scope" do
      expect(I18n.t("foobar", scope: [:foo, :bar])).to eq("Foobar")
    end

    it "highest scope" do
      expect(I18n.t("no_foobar", scope: [:foo, :bar])).to eq("No foobar")
    end

  end

  context "does not cascade when cascade is set to false" do

    it "returns an missing translation" do
      expect(I18n.t("other", scope: "chamber_of_commerce", cascade: false)).to include("Translation missing")
      expect(I18n.t("en", scope: "chamber_of_commerce", cascade: false)).to include("Chamber of Commerce")
    end
  end

end
