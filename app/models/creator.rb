# frozen_string_literal: true

class Creator < ApplicationRecord
  has_many :movie_creators
  has_many :movies, through: :movie_creators
end
