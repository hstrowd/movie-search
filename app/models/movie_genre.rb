# frozen_string_literal: true

class MovieGenre < ApplicationRecord
  self.table_name = :movies_genres

  belongs_to :movie
  belongs_to :genre
end
