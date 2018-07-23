# frozen_string_literal: true

class MovieKeyword < ApplicationRecord
  self.table_name = :movies_keywords

  belongs_to :movie
  belongs_to :keyword
end
