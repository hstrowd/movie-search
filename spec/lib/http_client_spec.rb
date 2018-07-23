# frozen_string_literal: true

require "rails_helper"
require "net/http"

RSpec.describe "HttpClient" do
  describe ".construct_url" do
    it "properly appends parameters to a URL with no params" do
      result = HttpClient.construct_url("http://www.example.com/search", param1: "bar", param2: "bar")
      expect(result).to eq("http://www.example.com/search?param1=bar&param2=bar")
    end

    it "properly appends additional parameters to a URL with existing params" do
      result = HttpClient.construct_url("http://www.example.com/search?acb=123", param1: "bar", param2: "bar")
      expect(result).to eq("http://www.example.com/search?acb=123&param1=bar&param2=bar")
    end

    it "properly appends parameters to a URL with a fragment" do
      result = HttpClient.construct_url("http://www.example.com/search#acb=123", param1: "bar", param2: "bar")
      expect(result).to eq("http://www.example.com/search?param1=bar&param2=bar#acb=123")
    end

    it "properly appends parameters to a relative, domain-less URL" do
      result = HttpClient.construct_url("/search", param1: "bar", param2: "bar")
      expect(result).to eq("/search?param1=bar&param2=bar")
    end

    it "handles an empty parameter set gracefully" do
      result = HttpClient.construct_url("http://www.example.com/search?acb=123", {})
      expect(result).to eq("http://www.example.com/search?acb=123")
    end

    it "returns nil if the URL is unable to be parsed" do
      result = HttpClient.construct_url("Not a URL", {})
      expect(result).to be_nil
    end
  end

  describe ".fetch_page" do
    let(:url) { "http://www.example.com/search?acb=123" }

    before do
      @page_content = "<html><body>Test Page</body></html>"
      allow(Net::HTTP).to receive(:get).and_return(@page_content)
    end

    it "loads the provided URL and returns the parsed content" do
      page_content = HttpClient.fetch_page(url)
      expect(page_content).to be_a(Nokogiri::HTML::Document)
      expect(page_content.text).to eq("Test Page")
    end

    it "returns nil if the page is unable to be fetched" do
      allow(Net::HTTP).to receive(:get).and_raise(Net::OpenTimeout.new("Test Error"))
      expect(HttpClient.fetch_page(url)).to be_nil
    end
  end
end
