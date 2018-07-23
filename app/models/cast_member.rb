# frozen_string_literal: true

class CastMember < ApplicationRecord
  has_many :movie_cast_members
  has_many :movies, through: :movie_cast_members
end
