# frozen_string_literal: true

require "net/http"

class HttpClient
  def self.construct_url(base_url, params)
    parsed_url = URI.parse(base_url)
    new_params = params.map { |key, value| "#{key}=#{value}" }
    parsed_url.query = new_params.unshift(parsed_url.query).compact.join("&")
    parsed_url.to_s
  rescue URI::InvalidURIError
    Rails.logger.warn("Invalid URL #{base_url}. Unable to process.")
    nil
  end

  def self.fetch_page(url)
    Nokogiri::HTML(Net::HTTP.get(URI(url)))
  rescue URI::InvalidURIError
    Rails.logger.warn("Invalid URL #{url}. Unable to process.")
    nil
  rescue Net::OpenTimeout
    Rails.logger.warn("Timeout attempting to fetch #{url}. Please try again.")
    nil
  end
end
