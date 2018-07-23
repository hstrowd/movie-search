# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Moves API (/api/movies)" do
  it "returns all movies, if no filter is specified" do
    Movie.create!(name: "Test Movie 1")
    Movie.create!(name: "Test Movie 2")
    Movie.create!(name: "Test Movie 3")

    get("/api/movies")

    expect(response).to be_successful
    response_payload = JSON.parse(response.body, symbolize_names: true)
    expect(response_payload[:data].length).to eq(3)
  end

  describe "payload structure" do
    it "returns all movie attributes in the payload" do
      movie = Movie.create!(name: "Test Movie 1",
                            brief_description: "Summary of movie 1.",
                            duration: 123,
                            imdb_url: "http://www.imdb.com/movie/1",
                            imdb_rank: "98",
                            imdb_stars: "7.25",
                            rating: "PG-13",
                            release_date: "2018-01-01")

      get("/api/movies")

      expect(response).to be_successful
      response_payload = JSON.parse(response.body, symbolize_names: true)
      expect(response_payload[:data].length).to eq(1)
      movie_payload = response_payload[:data].first

      expect(movie_payload[:id]).to eq(movie.id.to_s)
      expect(movie_payload[:type]).to eq("movies")
      expect(movie_payload[:attributes][:name]).to eq(movie.name)
      expect(movie_payload[:attributes][:brief_description]).to eq(movie.brief_description)
      expect(movie_payload[:attributes][:duration]).to eq(movie.duration)
      expect(movie_payload[:attributes][:imdb_url]).to eq(movie.imdb_url)
      expect(movie_payload[:attributes][:imdb_rank]).to eq(movie.imdb_rank)
      expect(movie_payload[:attributes][:imdb_stars]).to eq(movie.imdb_stars)
      expect(movie_payload[:attributes][:rating]).to eq(movie.rating)
      expect(movie_payload[:attributes][:release_date]).to eq(movie.release_date.iso8601)
    end
  end

  describe "relationships" do
    it "returns a relationship entry for cast members" do
      cast_member1 = CastMember.create!(name: "Chris Benjamin", tag: "chris-benjamin")
      cast_member2 = CastMember.create!(name: "Sarah Woods", tag: "sarah-woods")
      movie = Movie.create!(name: "Test Movie 1",
                            cast_members: [cast_member1, cast_member2])

      get("/api/movies?include=cast_members")

      expect(response).to be_successful
      response_payload = JSON.parse(response.body, symbolize_names: true)
      expect(response_payload[:data].length).to eq(1)
      movie_payload = response_payload[:data].first

      expect(movie_payload[:id]).to eq(movie.id.to_s)
      expect(movie_payload[:type]).to eq("movies")
      expect(movie_payload[:relationships][:cast_members][:data].length).to eq(2)
      response_cast_members = movie_payload[:relationships][:cast_members][:data].pluck(:id)
      expect(response_cast_members).to include(cast_member1.id.to_s)
      expect(response_cast_members).to include(cast_member2.id.to_s)
    end

    it "returns a relationship entry for creators" do
      creator1 = Creator.create!(name: "Sally Jameson", tag: "sally-jameson")
      creator2 = Creator.create!(name: "Jerry Smith", tag: "jerry-smith")
      movie = Movie.create!(name: "Test Movie 1",
                            creators: [creator1, creator2])

      get("/api/movies?include=creators")

      expect(response).to be_successful
      response_payload = JSON.parse(response.body, symbolize_names: true)
      expect(response_payload[:data].length).to eq(1)
      movie_payload = response_payload[:data].first

      expect(movie_payload[:id]).to eq(movie.id.to_s)
      expect(movie_payload[:type]).to eq("movies")
      expect(movie_payload[:relationships][:creators][:data].length).to eq(2)
      response_creators = movie_payload[:relationships][:creators][:data].pluck(:id)
      expect(response_creators).to include(creator1.id.to_s)
      expect(response_creators).to include(creator2.id.to_s)
    end

    it "returns a relationship entry for directors" do
      director1 = Director.create!(name: "Chris Benjamin", tag: "chris-benjamin")
      director2 = Director.create!(name: "Susan Thompson", tag: "susan-thompson")
      movie = Movie.create!(name: "Test Movie 1",
                            directors: [director1, director2])

      get("/api/movies?include=directors")
      expect(response).to be_successful
      response_payload = JSON.parse(response.body, symbolize_names: true)
      expect(response_payload[:data].length).to eq(1)
      movie_payload = response_payload[:data].first

      expect(movie_payload[:id]).to eq(movie.id.to_s)
      expect(movie_payload[:type]).to eq("movies")
      expect(movie_payload[:relationships][:directors][:data].length).to eq(2)
      response_directors = movie_payload[:relationships][:directors][:data].pluck(:id)
      expect(response_directors).to include(director1.id.to_s)
      expect(response_directors).to include(director2.id.to_s)
    end

    it "returns a relationship entry for genres" do
      genre1 = Genre.create!(name: "Action", tag: "action")
      genre2 = Genre.create!(name: "Comedy", tag: "comedy")
      movie = Movie.create!(name: "Test Movie 1",
                            genres: [genre1, genre2])

      get("/api/movies?include=genres")

      expect(response).to be_successful
      response_payload = JSON.parse(response.body, symbolize_names: true)
      expect(response_payload[:data].length).to eq(1)
      movie_payload = response_payload[:data].first

      expect(movie_payload[:id]).to eq(movie.id.to_s)
      expect(movie_payload[:type]).to eq("movies")
      expect(movie_payload[:relationships][:genres][:data].length).to eq(2)
      response_genres = movie_payload[:relationships][:genres][:data].pluck(:id)
      expect(response_genres).to include(genre1.id.to_s)
      expect(response_genres).to include(genre2.id.to_s)
    end

    it "returns a relationship entry for keywords" do
      keyword1 = Keyword.create!(name: "World War II", tag: "world-war-ii")
      keyword2 = Keyword.create!(name: "Historical fiction", tag: "historical-fiction")
      movie = Movie.create!(name: "Test Movie 1",
                            keywords: [keyword1, keyword2])

      get("/api/movies?include=keywords")

      expect(response).to be_successful
      response_payload = JSON.parse(response.body, symbolize_names: true)
      expect(response_payload[:data].length).to eq(1)
      movie_payload = response_payload[:data].first

      expect(movie_payload[:id]).to eq(movie.id.to_s)
      expect(movie_payload[:type]).to eq("movies")
      expect(movie_payload[:relationships][:keywords][:data].length).to eq(2)
      response_keywords = movie_payload[:relationships][:keywords][:data].pluck(:id)
      expect(response_keywords).to include(keyword1.id.to_s)
      expect(response_keywords).to include(keyword2.id.to_s)
    end
  end

  describe "filtering" do
    it "supports freetext searches based on names" do
      Movie.create!(name: "The Incredibles").update_search
      Movie.create!(name: "Saving Private Ryan").update_search
      Movie.create!(name: "Indiana Jones and the Last Crusade").update_search
      Movie.create!(name: "Keeping Up with the Jones's").update_search
      Movie.create!(name: "The Incredibles 2").update_search
      Movie.create!(name: "Indiana Jones and the Temple of Doom").update_search

      get("/api/movies?filter[search]=jones")

      expect(response).to be_successful
      response_payload = JSON.parse(response.body, symbolize_names: true)
      expect(response_payload[:data].length).to eq(3)

      response_movies = response_payload[:data].pluck(:id).collect { |id| Movie.find(id).name }
      expect(response_movies).to include("Indiana Jones and the Last Crusade")
      expect(response_movies).to include("Keeping Up with the Jones's")
      expect(response_movies).to include("Indiana Jones and the Temple of Doom")
    end

    it "supports freetext searches based on descriptions" do
      Movie.create!(name: "The Incredibles",
                    brief_description: "The story of a spectacular family with incredible powers.").update_search
      Movie.create!(name: "Saving Private Ryan",
                    brief_description: "A tale of bravery in combat.").update_search
      Movie.create!(name: "Indiana Jones and the Last Crusade",
                    brief_description: "Indi's latest adventure takes him on a spectacular adventure around the globe.").update_search
      Movie.create!(name: "Keeping Up with the Jones's",
                    brief_description: "Just another day in the life of a modern American family.").update_search
      Movie.create!(name: "The Incredibles 2",
                    brief_description: "We check back in with our favority superhero, crime fighting for a special update").update_search
      Movie.create!(name: "Indiana Jones and the Temple of Doom",
                    brief_description: "Dr Jones risks life and limb in this dramatic tale full of danger.").update_search

      get("/api/movies?filter[search]=spectacular")

      expect(response).to be_successful
      response_payload = JSON.parse(response.body, symbolize_names: true)
      expect(response_payload[:data].length).to eq(2)

      response_movies = response_payload[:data].pluck(:id).collect { |id| Movie.find(id).name }
      expect(response_movies).to include("The Incredibles")
      expect(response_movies).to include("Indiana Jones and the Last Crusade")
    end

    it "supports freetext searches based on cast members" do
      james_thompson = CastMember.create(name: "James Thompson", tag: "james-thompson")
      susan_smith = CastMember.create(name: "Susan Smith", tag: "susan-smith")
      billy_james = CastMember.create(name: "Billy James", tag: "billy-james")
      chris_smith = CastMember.create(name: "Chris Smith", tag: "chris-smith")

      Movie.create!(name: "The Incredibles", cast_members: [chris_smith, james_thompson]).update_search
      Movie.create!(name: "Saving Private Ryan", cast_members: [susan_smith]).update_search
      Movie.create!(name: "Indiana Jones and the Last Crusade", cast_members: [susan_smith, billy_james]).update_search
      Movie.create!(name: "Keeping Up with the Jones's", cast_members: [james_thompson]).update_search
      Movie.create!(name: "The Incredibles 2", cast_members: [billy_james, james_thompson]).update_search
      Movie.create!(name: "Indiana Jones and the Temple of Doom", cast_members: [chris_smith]).update_search

      get("/api/movies?filter[search]=james")

      expect(response).to be_successful
      response_payload = JSON.parse(response.body, symbolize_names: true)
      expect(response_payload[:data].length).to eq(4)

      response_movies = response_payload[:data].pluck(:id).collect { |id| Movie.find(id).name }
      expect(response_movies).to include("The Incredibles")
      expect(response_movies).to include("Indiana Jones and the Last Crusade")
      expect(response_movies).to include("Keeping Up with the Jones's")
      expect(response_movies).to include("The Incredibles 2")
    end

    it "supports freetext searches based on creators" do
      james_thompson = Creator.create(name: "James Thompson", tag: "james-thompson")
      susan_smith = Creator.create(name: "Susan Smith", tag: "susan-smith")
      billy_james = Creator.create(name: "Billy James", tag: "billy-james")
      chris_smith = Creator.create(name: "Chris Smith", tag: "chris-smith")

      Movie.create!(name: "The Incredibles", creators: [chris_smith, james_thompson]).update_search
      Movie.create!(name: "Saving Private Ryan", creators: [susan_smith]).update_search
      Movie.create!(name: "Indiana Jones and the Last Crusade", creators: [susan_smith, billy_james]).update_search
      Movie.create!(name: "Keeping Up with the Jones's", creators: [james_thompson]).update_search
      Movie.create!(name: "The Incredibles 2", creators: [billy_james, james_thompson]).update_search
      Movie.create!(name: "Indiana Jones and the Temple of Doom", creators: [chris_smith]).update_search

      get("/api/movies?filter[search]=james")

      expect(response).to be_successful
      response_payload = JSON.parse(response.body, symbolize_names: true)
      expect(response_payload[:data].length).to eq(4)

      response_movies = response_payload[:data].pluck(:id).collect { |id| Movie.find(id).name }
      expect(response_movies).to include("The Incredibles")
      expect(response_movies).to include("Indiana Jones and the Last Crusade")
      expect(response_movies).to include("Keeping Up with the Jones's")
      expect(response_movies).to include("The Incredibles 2")
    end

    it "supports freetext searches based on directors" do
      james_thompson = Director.create(name: "James Thompson", tag: "james-thompson")
      susan_smith = Director.create(name: "Susan Smith", tag: "susan-smith")
      billy_james = Director.create(name: "Billy James", tag: "billy-james")
      chris_smith = Director.create(name: "Chris Smith", tag: "chris-smith")

      Movie.create!(name: "The Incredibles", directors: [chris_smith, james_thompson]).update_search
      Movie.create!(name: "Saving Private Ryan", directors: [susan_smith]).update_search
      Movie.create!(name: "Indiana Jones and the Last Crusade", directors: [susan_smith, billy_james]).update_search
      Movie.create!(name: "Keeping Up with the Jones's", directors: [james_thompson]).update_search
      Movie.create!(name: "The Incredibles 2", directors: [billy_james, james_thompson]).update_search
      Movie.create!(name: "Indiana Jones and the Temple of Doom", directors: [chris_smith]).update_search

      get("/api/movies?filter[search]=james")

      expect(response).to be_successful
      response_payload = JSON.parse(response.body, symbolize_names: true)
      expect(response_payload[:data].length).to eq(4)

      response_movies = response_payload[:data].pluck(:id).collect { |id| Movie.find(id).name }
      expect(response_movies).to include("The Incredibles")
      expect(response_movies).to include("Indiana Jones and the Last Crusade")
      expect(response_movies).to include("Keeping Up with the Jones's")
      expect(response_movies).to include("The Incredibles 2")
    end

    it "supports freetext searches based on genres" do
      horror = Genre.create(name: "Horror", tag: "horror")
      action = Genre.create(name: "Action", tag: "action")
      comedy = Genre.create(name: "Comedy", tag: "comedy")
      adventure = Genre.create(name: "Adventure", tag: "adventure")

      Movie.create!(name: "The Incredibles", genres: [horror, action]).update_search
      Movie.create!(name: "Saving Private Ryan", genres: [comedy, adventure]).update_search
      Movie.create!(name: "Indiana Jones and the Last Crusade", genres: [adventure, horror]).update_search
      Movie.create!(name: "Keeping Up with the Jones's", genres: [comedy]).update_search
      Movie.create!(name: "The Incredibles 2", genres: [action, comedy]).update_search
      Movie.create!(name: "Indiana Jones and the Temple of Doom", genres: [adventure]).update_search

      get("/api/movies?filter[search]=adventure")

      expect(response).to be_successful
      response_payload = JSON.parse(response.body, symbolize_names: true)
      expect(response_payload[:data].length).to eq(3)

      response_movies = response_payload[:data].pluck(:id).collect { |id| Movie.find(id).name }
      expect(response_movies).to include("Saving Private Ryan")
      expect(response_movies).to include("Indiana Jones and the Last Crusade")
      expect(response_movies).to include("Indiana Jones and the Temple of Doom")
    end

    it "supports freetext searches based on keywords" do
      world_war_ii = Keyword.create(name: "World War II", tag: "world-war-ii")
      bravery = Keyword.create(name: "Bravery", tag: "bravery")
      family_friendly = Keyword.create(name: "Family friendly", tag: "family-friendly")
      world_wide = Keyword.create(name: "World-wide Release", tag: "world-wide-release")

      Movie.create!(name: "The Incredibles", keywords: [family_friendly, world_wide]).update_search
      Movie.create!(name: "Saving Private Ryan", keywords: [world_war_ii, bravery]).update_search
      Movie.create!(name: "Indiana Jones and the Last Crusade", keywords: [world_wide]).update_search
      Movie.create!(name: "Keeping Up with the Jones's", keywords: [family_friendly]).update_search
      Movie.create!(name: "The Incredibles 2", keywords: [bravery, family_friendly]).update_search
      Movie.create!(name: "Indiana Jones and the Temple of Doom", keywords: [world_war_ii]).update_search

      get("/api/movies?filter[search]=world")

      expect(response).to be_successful
      response_payload = JSON.parse(response.body, symbolize_names: true)
      expect(response_payload[:data].length).to eq(4)

      response_movies = response_payload[:data].pluck(:id).collect { |id| Movie.find(id).name }
      expect(response_movies).to include("The Incredibles")
      expect(response_movies).to include("Saving Private Ryan")
      expect(response_movies).to include("Indiana Jones and the Last Crusade")
      expect(response_movies).to include("Indiana Jones and the Temple of Doom")
    end

    it "requires a wildcard character to be used to match partial words" do
      Movie.create!(name: "The Incredibles",
                    brief_description: "The story of a spectacular family with incredible powers.").update_search
      Movie.create!(name: "Saving Private Ryan",
                    brief_description: "A tale of brave soldier in combat.").update_search
      Movie.create!(name: "Indiana Jones and the Last Crusade",
                    brief_description: "Indi's latest adventure takes him on a spectacular adventure around the globe.").update_search
      Movie.create!(name: "Keeping Up with the Jones's",
                    brief_description: "Just another day in the life of a modern American family.").update_search
      Movie.create!(name: "The Incredibles 2",
                    brief_description: "We check back in with our favority superhero, crime fighting for a special update").update_search
      Movie.create!(name: "Indiana Jones and the Temple of Doom",
                    brief_description: "Dr Jones risks life and limb in this dramatic tale full of danger and bravery.").update_search

      get("/api/movies?filter[search]=brave")
      expect(response).to be_successful
      response_payload = JSON.parse(response.body, symbolize_names: true)
      expect(response_payload[:data].length).to eq(1)
      expect(response_payload[:data].first[:attributes][:name]).to include("Saving Private Ryan")

      get("/api/movies?filter[search]=bravery")
      expect(response).to be_successful
      response_payload = JSON.parse(response.body, symbolize_names: true)
      expect(response_payload[:data].length).to eq(1)
      expect(response_payload[:data].first[:attributes][:name]).to include("Indiana Jones and the Temple of Doom")

      get("/api/movies?filter[search]=*brave*")
      expect(response).to be_successful
      response_payload = JSON.parse(response.body, symbolize_names: true)
      expect(response_payload[:data].length).to eq(2)
      response_movies = response_payload[:data].pluck(:id).collect { |id| Movie.find(id).name }
      expect(response_movies).to include("Saving Private Ryan")
      expect(response_movies).to include("Indiana Jones and the Temple of Doom")
    end

    it "allows multiple conditions to be specified using AND/OR keywords" do
      Movie.create!(name: "The Incredibles",
                    brief_description: "The story of a spectacular family with incredible powers.").update_search
      Movie.create!(name: "Saving Private Ryan",
                    brief_description: "A tale of bravery in combat.").update_search
      Movie.create!(name: "Indiana Jones and the Last Crusade",
                    brief_description: "Indi's latest adventure takes him on a spectacular trip around the globe.").update_search
      Movie.create!(name: "Keeping Up with the Jones's",
                    brief_description: "Just another day in the life of a modern American family.").update_search
      Movie.create!(name: "The Incredibles 2",
                    brief_description: "We check back in with our favority superhero, crime fighting for a spectacular update").update_search
      Movie.create!(name: "Indiana Jones and the Temple of Doom",
                    brief_description: "Dr Jones risks life and limb in this dramatic adventure full of danger.").update_search

      get("/api/movies?filter[search]=spectacular+(story+OR+adventure)")
      expect(response).to be_successful
      response_payload = JSON.parse(response.body, symbolize_names: true)
      expect(response_payload[:data].length).to eq(2)
      response_movies = response_payload[:data].pluck(:id).collect { |id| Movie.find(id).name }
      expect(response_movies).to include("The Incredibles")
      expect(response_movies).to include("Indiana Jones and the Last Crusade")
    end
  end
end
