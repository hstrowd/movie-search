# frozen_string_literal: true

class Director < ApplicationRecord
  has_many :movie_directors
  has_many :movies, through: :movie_directors
end
