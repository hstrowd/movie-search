# frozen_string_literal: true

module Api
  class GenreResource < BaseResource
    attributes :name

    has_many :movies
  end
end
