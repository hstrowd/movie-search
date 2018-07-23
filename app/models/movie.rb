# frozen_string_literal: true

class Movie < ApplicationRecord
  has_many :movie_genres
  has_many :genres, through: :movie_genres

  has_many :movie_directors
  has_many :directors, through: :movie_directors

  has_many :movie_creators
  has_many :creators, through: :movie_creators

  has_many :movie_cast_members
  has_many :cast_members, through: :movie_cast_members

  has_many :movie_keywords
  has_many :keywords, through: :movie_keywords

  def update_search
    movie_search = MoviesSearch.find_or_initialize_by(id: id)
    search_content = "#{name}; #{brief_description}; #{cast_members.pluck(:name).join(', ')}; " \
                     "#{creators.pluck(:name).join(', ')}; #{directors.pluck(:name).join(', ')}; " \
                     "#{genres.pluck(:name).join(', ')}; #{keywords.pluck(:name).join(', ')}"

    return if movie_search.update(search_content: search_content)
    Rails.logger.warn("Unable to update the search cache for movie #{id}. Please re-trigger the update for this movie.")
  end
end
