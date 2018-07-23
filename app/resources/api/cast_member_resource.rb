# frozen_string_literal: true

module Api
  class CastMemberResource < BaseResource
    attributes :name

    has_many :movies
  end
end
