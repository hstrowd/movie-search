# frozen_string_literal: true

module Api
  class CreatorResource < BaseResource
    attributes :name

    has_many :movies
  end
end
