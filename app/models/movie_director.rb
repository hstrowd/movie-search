# frozen_string_literal: true

class MovieDirector < ApplicationRecord
  self.table_name = :movies_directors

  belongs_to :movie
  belongs_to :director
end
