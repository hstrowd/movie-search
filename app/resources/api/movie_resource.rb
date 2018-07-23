# frozen_string_literal: true

module Api
  class MovieResource < BaseResource
    attributes :name,
               :brief_description,
               :imdb_rank,
               :imdb_stars,
               :imdb_url,
               :duration,
               :rating,
               :release_date

    has_many :cast_members
    has_many :creators
    has_many :directors
    has_many :genres
    has_many :keywords

    filter :search, apply: ->(records, value, _options) { # rubocop:disable Style/Lambda
      search_results = MoviesSearch.where("search_content MATCH ?", value)
      records.where(id: search_results.pluck(:id))
    }
  end
end
