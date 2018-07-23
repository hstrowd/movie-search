# frozen_string_literal: true

class MovieCreator < ApplicationRecord
  self.table_name = :movies_creators

  belongs_to :movie
  belongs_to :creator
end
