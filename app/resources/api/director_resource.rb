# frozen_string_literal: true

module Api
  class DirectorResource < BaseResource
    attributes :name

    has_many :movies
  end
end
