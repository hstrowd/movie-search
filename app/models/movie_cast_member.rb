# frozen_string_literal: true

class MovieCastMember < ApplicationRecord
  self.table_name = :movies_cast_members

  belongs_to :movie
  belongs_to :cast_member
end
