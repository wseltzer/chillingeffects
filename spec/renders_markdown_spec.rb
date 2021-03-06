require 'spec_helper'

describe Markdown do
  it "renders markdown to html" do
    html = Markdown.render("some *nice* markdown")

    expect(html).to eq "<p>some <em>nice</em> markdown</p>\n"
  end

  it "reuses the same RedCarpet::Markdown instance" do
    Redcarpet::Markdown.should_not_receive(:new)

    Markdown.render("markdown")
    Markdown.render("markdown")
  end
end
