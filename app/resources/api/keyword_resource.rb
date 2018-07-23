# frozen_string_literal: true

module Api
  class KeywordResource < BaseResource
    attributes :name

    has_many :movies
  end
end
