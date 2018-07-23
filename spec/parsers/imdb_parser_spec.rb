# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ImdbParser" do
  after do
    # Reset record caches since the DB is rolled back after each test.
    ImdbParser.instance_variable_set(:@movies, nil)
    ImdbParser.instance_variable_set(:@genres, nil)
  end

  describe ".load_list" do
    let(:list_url) { "http://www.example.com/movies" }

    it "does nothing if the list URL is unable to be constructed" do
      expect(ImdbParser).not_to receive(:parse_movie_list)
      ImdbParser.load_list(url: "Invalid URL", page: 3)
    end

    it "does nothing if the list URL fails to be fetched" do
      allow(HttpClient).to receive(:fetch_page).and_return(nil)
      expect(ImdbParser).not_to receive(:parse_movie_list)
      ImdbParser.load_list(url: "Invalid URL", page: 3)
    end

    it "loads the content for the URL and triggers the contained movies to be parsed" do
      page_content = Nokogiri::HTML("<html></html>")
      allow(HttpClient).to receive(:fetch_page).with("http://www.example.com/movies?page=3")
                                               .and_return(page_content)
      expect(ImdbParser).to receive(:parse_movie_list).with(page_content)

      ImdbParser.load_list(url: list_url, page: 3)
    end

    it "triggers the next page to be fetched if the next page link is present" do
      next_page_link = <<-HTML
        <div id="main">
          <div class="lister">
            <div class="nav">
              <a class="lister-page-next next-page">Next Page</a>
            </div>
          </div>
        </div>
      HTML
      page_content = Nokogiri::HTML("<html>#{next_page_link}</html>")
      allow(HttpClient).to receive(:fetch_page).with("http://www.example.com/movies?page=3")
                                               .and_return(page_content)
      # Asserting recursion on the method under test requires this bit of hoop-jumping to allow the
      # original call to proceed unaffected while also asserting the parameters for the second call
      # to the same method.
      second_call = false
      original_method = ImdbParser.method(:load_list)
      expect(ImdbParser).to receive(:load_list).twice do |args|
        if !second_call
          second_call = true
          original_method.call(args)
        else
          expect(args[:url]).to eq(list_url)
          expect(args[:page]).to eq(4)
        end
      end
      ImdbParser.load_list(url: list_url, page: 3)
    end

    it "does NOT trigger the next page to be fetched if the next page link is not present on the page" do
      page_content = Nokogiri::HTML("<html></html>")
      allow(HttpClient).to receive(:fetch_page).with("http://www.example.com/movies?page=3")
                                               .and_return(page_content)
      expect(ImdbParser).not_to receive(:load_list).with(hash_including(page: 4))
      ImdbParser.load_list(url: list_url, page: 3)
    end

    it "uses a default page value of 1, if no page argument is provided" do
      page_content = Nokogiri::HTML("<html></html>")
      allow(HttpClient).to receive(:fetch_page).with("http://www.example.com/movies?page=1")
                                               .and_return(page_content)
      ImdbParser.load_list(url: list_url, page: 1)
    end
  end

  describe ".parse_movie_list" do
    it "does nothing if no movies are found on the page" do
      expect(ImdbParser).not_to receive(:extract_movie_overview)
      expect(ImdbParser).not_to receive(:fetch_movie_details)
      expect(ImdbParser).not_to receive(:add_or_update_movie)

      page_content = Nokogiri::HTML("<html></html>")
      ImdbParser.parse_movie_list(page_content)
    end

    it "processes each movie contained within the provided page" do
      overview_content = { name: "Test Movie" }
      expect(ImdbParser).to receive(:extract_movie_overview).exactly(3).times
        .with(instance_of(Nokogiri::XML::Element))
                                                            .and_return(overview_content)
      details_content = { name: "Test Movie", director: "John Doe" }
      expect(ImdbParser).to receive(:fetch_movie_details).exactly(3).times
        .with(overview_content)
                                                         .and_return(details_content)
      expect(ImdbParser).to receive(:add_or_update_movie).exactly(3).times
        .with(details_content)
                                                         .and_return(Movie.new)

      movie_list_entries = <<-HTML
        <div id="main">
          <div class="lister">
            <div class="lister-list">
              <div class="lister-item">Movie 1 - Overview Content</div>
              <div class="lister-item">Movie 2 - Overview Content</div>
              <div class="lister-item">Movie 3 - Overview Content</div>
            </div>
          </div>
        </div>
      HTML
      page_content = Nokogiri::HTML("<html>#{movie_list_entries}</html>")

      results = ImdbParser.parse_movie_list(page_content)

      expect(results.length).to eq(3)
    end

    it "gracefully ignores movie entries that are unable to be parsed" do
      expect(ImdbParser).to receive(:extract_movie_overview).and_return(nil)
      expect(ImdbParser).not_to receive(:fetch_movie_details)
      expect(ImdbParser).not_to receive(:add_or_update_movie)

      movie_list_entries = <<-HTML
        <div id="main">
          <div class="lister">
            <div class="lister-list">
              <div class="lister-item">Movie 1 - Overview Content</div>
            </div>
          </div>
        </div>
      HTML
      page_content = Nokogiri::HTML("<html>#{movie_list_entries}</html>")

      results = ImdbParser.parse_movie_list(page_content)

      expect(results.length).to eq(0)
    end
  end

  describe ".extract_movie_overview" do
    it "returns nil if the movies name is unable to be found" do
      movie_overview_html = "<div class=\"lister-item\">Movie 1 - Overview Content</div>"
      movie_overview_element = Nokogiri::XML::Element.new("movie-overview",
                                                          Nokogiri::XML::Document.parse(movie_overview_html))

      expect(ImdbParser.extract_movie_overview(movie_overview_element)).to be_nil
    end

    it "gracefully ignores any missing values other than the name" do
      movie_overview_html = <<-HTML
        <div class="lister-item">
          <div class="lister-item-header">
            <a>Test Movie 1</a>
          </div>
        </div>
      HTML
      movie_overview_element = Nokogiri::XML::Document.parse(movie_overview_html).root

      movie_attrs = ImdbParser.extract_movie_overview(movie_overview_element)
      expect(movie_attrs[:name]).to eq("Test Movie 1")
    end

    it "parses all overview attributes out of the overview element" do
      movie_overview_html = <<-HTML
        <div class="lister-item">
          <div class="lister-item-header">
            <div class="lister-item-index">98.</div>
            <a href="/movie/1">Test Movie 1</a>
          </div>
          <div class="certificate">PG-13</div>
          <div class="runtime">123 min</div>
          <div class="genre">Action, Horror, Comedy</div>
        </div>
      HTML
      movie_overview_element = Nokogiri::XML::Document.parse(movie_overview_html).root

      movie_attrs = ImdbParser.extract_movie_overview(movie_overview_element)
      expect(movie_attrs[:name]).to eq("Test Movie 1")
      expect(movie_attrs[:imdb_url]).to eq("https://www.imdb.com/movie/1")
      expect(movie_attrs[:imdb_rank]).to eq("98")
      expect(movie_attrs[:rating]).to eq("PG-13")
      expect(movie_attrs[:duration]).to eq(123)
      expect(movie_attrs[:genres]).to eq(%w[Action Horror Comedy])
    end

    it "does not add the base URL for links that already include it" do
      movie_overview_html = <<-HTML
        <div class="lister-item">
          <div class="lister-item-header">
            <div class="lister-item-index">98.</div>
            <a href="https://www.imdb.com/movie/1">Test Movie 1</a>
          </div>
        </div>
      HTML
      movie_overview_element = Nokogiri::XML::Document.parse(movie_overview_html).root

      movie_attrs = ImdbParser.extract_movie_overview(movie_overview_element)
      expect(movie_attrs[:imdb_url]).to eq("https://www.imdb.com/movie/1")
    end
  end

  describe ".fetch_movie_details" do
    it "returns nil if no IMDB url is defined for the movie" do
      expect(ImdbParser.fetch_movie_details({})).to eq({})
    end

    it "returns gracefully ignores any missing values" do
      movie_attrs = { name: "Test Movie 1", imdb_url: "http://www.imdb.com/movie/1" }
      page_content = Nokogiri::HTML("<html></html>")
      allow(HttpClient).to receive(:fetch_page).with(movie_attrs[:imdb_url])
                                               .and_return(page_content)

      movie_details = ImdbParser.fetch_movie_details(movie_attrs)
      expect(movie_details[:name]).to eq(movie_attrs[:name])
      expect(movie_details[:imdb_url]).to eq(movie_attrs[:imdb_url])
    end

    it "extracts all details attributes from the fetched page" do
      movie_attrs = { name: "Test Movie 1", imdb_url: "http://www.imdb.com/movie/1" }
      movie_details_html = <<-HTML
        <html>
          <div id="main_top">
            <div class="summary_text">Summary of movie 1.</div>
            <meta itemprop="datePublished" content="2018-01-01" />
            <div class="ratingValue">
              <div itemprop="ratingValue">7.25</div>
            </div>
            <div>
              <div class="credit_summary_item">
                <div itemprop="director">
                  <div itemprop="name">James Drew</div>
                </div>
              </div>
              <div class="credit_summary_item">
                <div itemprop="director">
                  <div itemprop="name">Susan Thompson</div>
                </div>
              </div>
            </div>
            <div>
              <div class="credit_summary_item">
                <div itemprop="creator">
                  <div itemprop="name">Sally Jameson</div>
                </div>
              </div>
              <div class="credit_summary_item">
                <div itemprop="creator">
                  <div itemprop="name">Jerry Smith</div>
                </div>
              </div>
              <div class="credit_summary_item">
                <div itemprop="creator">
                  <div itemprop="name">Sam Caldwell</div>
                </div>
              </div>
            </div>
          </div>
          <div id="main_bottom">
            <div class="cast_list">
                <div itemprop="actor">
                  <div itemprop="name">Chris Benjamin</div>
                </div>
                <div itemprop="actor">
                  <div itemprop="name">Sarah Woods</div>
                </div>
                <div itemprop="actor">
                  <div itemprop="name">Matt Dobson</div>
                </div>
                <div itemprop="actor">
                  <div itemprop="name">Mary Tulley</div>
                </div>
            </div>
            <div class="article">
              <div itemprop="keywords">
                <a><span itemprop="keywords">World War II</span></a>
                <a><span itemprop="keywords">Historical fiction</span></a>
                <a><span itemprop="keywords">Bravery</span></a>
              </div>
            </div>
          </div>
        </html>
      HTML
      page_content = Nokogiri::HTML(movie_details_html)
      allow(HttpClient).to receive(:fetch_page).with(movie_attrs[:imdb_url])
                                               .and_return(page_content)

      movie_details = ImdbParser.fetch_movie_details(movie_attrs)
      expect(movie_details[:brief_description]).to eq("Summary of movie 1.")
      expect(movie_details[:release_date]).to eq("2018-01-01")
      expect(movie_details[:imdb_stars]).to eq("7.25")
      expect(movie_attrs[:directors]).to eq(["James Drew", "Susan Thompson"])
      expect(movie_attrs[:creators]).to eq(["Sally Jameson", "Jerry Smith", "Sam Caldwell"])
      expect(movie_attrs[:cast_members]).to eq(["Chris Benjamin", "Sarah Woods", "Matt Dobson", "Mary Tulley"])
      expect(movie_attrs[:keywords]).to eq(["World War II", "Historical fiction", "Bravery"])
    end
  end

  describe ".add_or_update_movie" do
    let(:cast_members) { ["Chris Benjamin", "Sarah Woods", "Matt Dobson", "Mary Tulley"] }
    let(:creators) { ["Sally Jameson", "Jerry Smith", "Sam Caldwell"] }
    let(:directors) { ["James Drew", "Susan Thompson"] }
    let(:genres) { %w[Action Horror Comedy] }
    let(:keywords) { ["World War II", "Historical fiction", "Bravery"] }
    let(:movie_attrs) do
      {
        name: "Test Movie 1",
        brief_description: "Summary of movie 1.",
        cast_members: cast_members,
        creators: creators,
        directors: directors,
        duration: 123,
        genres: genres,
        imdb_url: "http://www.imdb.com/movie/1",
        imdb_rank: "98",
        imdb_stars: "7.25",
        keywords: keywords,
        rating: "PG-13",
        release_date: "2018-01-01"
      }
    end

    it "ignores the request if the provided attributes do not include a name" do
      expect(ImdbParser.add_or_update_movie({})).to be_nil
    end

    it "updates the existing record for the movie, if one exists with the same name" do
      existing_movie = Movie.create!(name: movie_attrs[:name])

      result = nil
      expect do
        result = ImdbParser.add_or_update_movie(movie_attrs)
      end.not_to(change { Movie.count })

      expect(result.valid?).to be_truthy
      expect(result.id).to eq(existing_movie.id)
      expect(result.name).to eq(movie_attrs[:name])
      expect(result.brief_description).to eq(movie_attrs[:brief_description])
      expect(result.cast_members.length).to eq(cast_members.count)
      cast_members.each { |cast_member_name| expect(result.cast_members.pluck(:name)).to include(cast_member_name) }
      expect(result.creators.length).to eq(creators.count)
      creators.each { |creator_name| expect(result.creators.pluck(:name)).to include(creator_name) }
      expect(result.directors.length).to eq(directors.count)
      directors.each { |director_name| expect(result.directors.pluck(:name)).to include(director_name) }
      expect(result.duration).to eq(movie_attrs[:duration].to_i)
      expect(result.genres.length).to eq(genres.count)
      genres.each { |genre_name| expect(result.genres.pluck(:name)).to include(genre_name) }
      expect(result.imdb_url).to eq(movie_attrs[:imdb_url])
      expect(result.imdb_rank).to eq(movie_attrs[:imdb_rank].to_i)
      expect(result.imdb_stars).to be_within(0.01).of(movie_attrs[:imdb_stars].to_f)
      expect(result.keywords.length).to eq(keywords.count)
      keywords.each { |keyword_name| expect(result.keywords.pluck(:name)).to include(keyword_name) }
      expect(result.rating).to eq(movie_attrs[:rating])
      expect(result.release_date).to eq(movie_attrs[:release_date].to_date)
    end

    it "creates a new record for the movie, if none exist with the same name" do
      result = nil
      expect do
        result = ImdbParser.add_or_update_movie(movie_attrs)
      end.to change { Movie.count }.by(1)

      expect(result.valid?).to be_truthy
      expect(result.id).not_to be_nil
      expect(result.name).to eq(movie_attrs[:name])
      expect(result.brief_description).to eq(movie_attrs[:brief_description])
      expect(result.cast_members.length).to eq(cast_members.count)
      cast_members.each { |cast_member_name| expect(result.cast_members.pluck(:name)).to include(cast_member_name) }
      expect(result.creators.length).to eq(creators.count)
      creators.each { |creator_name| expect(result.creators.pluck(:name)).to include(creator_name) }
      expect(result.directors.length).to eq(directors.count)
      directors.each { |director_name| expect(result.directors.pluck(:name)).to include(director_name) }
      expect(result.duration).to eq(movie_attrs[:duration].to_i)
      expect(result.genres.length).to eq(genres.count)
      genres.each { |genre_name| expect(result.genres.pluck(:name)).to include(genre_name) }
      expect(result.imdb_url).to eq(movie_attrs[:imdb_url])
      expect(result.imdb_rank).to eq(movie_attrs[:imdb_rank].to_i)
      expect(result.imdb_stars).to be_within(0.01).of(movie_attrs[:imdb_stars].to_f)
      expect(result.keywords.length).to eq(keywords.count)
      keywords.each { |keyword_name| expect(result.keywords.pluck(:name)).to include(keyword_name) }
      expect(result.rating).to eq(movie_attrs[:rating])
      expect(result.release_date).to eq(movie_attrs[:release_date].to_date)
    end

    it "adds a newly created movie to the internal cache" do
      expect(ImdbParser.movies[movie_attrs[:name]]).to be_nil

      result = nil
      expect do
        result = ImdbParser.add_or_update_movie(movie_attrs)
      end.to change { Movie.count }.by(1)

      expect(Movie).not_to receive(:all)
      expect(ImdbParser.movies[movie_attrs[:name]]).to eq(result)
    end
  end

  describe ".find_or_create_lookup_records" do
    let(:cast_members) { ["Chris Benjamin", "Sarah Woods", "Matt Dobson", "Mary Tulley"] }
    let(:creators) { ["Sally Jameson", "Jerry Smith", "Sam Caldwell"] }
    let(:directors) { ["James Drew", "Susan Thompson"] }
    let(:genres) { %w[Action Horror Comedy] }
    let(:keywords) { ["World War II", "Historical fiction", "Bravery"] }
    let(:movie_attrs) do
      {
        name: "Test Movie 1",
        cast_members: cast_members,
        creators: creators,
        directors: directors,
        genres: genres,
        keywords: keywords
      }
    end

    it "returns an empty array if no internal cache is setup for the relationship" do
      expect(ImdbParser.find_or_create_lookup_records(:invalid, movie_attrs)).to eq([])
    end

    it "returns an empty array if no model is found for the relatioship" do
      # Defines an internal cache method for the relatonship so that check is not tripped.
      class ImdbParser
        def self.test_lookup_records
          []
        end
      end
      expect(ImdbParser.find_or_create_lookup_records(:test_lookup_records, movie_attrs)).to eq([])
    end

    it "creates new lookup records for values that do not already exist" do
      results = nil
      expect do
        results = ImdbParser.find_or_create_lookup_records(:genres, movie_attrs)
      end.to change { Genre.count }.by(genres.count)

      results.each { |genre| expect(genres).to include(genre.name) }
    end

    it "assigns the movie to the existing lookup records for values that already exist" do
      existing_genres = genres.collect { |genre_name| Genre.create!(name: genre_name, tag: genre_name.parameterize) }

      results = nil
      expect do
        results = ImdbParser.find_or_create_lookup_records(:genres, movie_attrs)
      end.not_to(change { Genre.count })

      results.each { |genre| expect(existing_genres).to include(genre) }
    end

    it "adds a newly created lookup records to the internal cache" do
      genres.each { |genre_name| expect(ImdbParser.genres[genre_name.parameterize]).to be_nil }

      results = nil
      expect do
        results = ImdbParser.find_or_create_lookup_records(:genres, movie_attrs)
      end.to change { Genre.count }.by(genres.count)

      expect(Genre).not_to receive(:all)
      results.each { |genre| expect(ImdbParser.genres[genre.tag]).to eq(genre) }
    end

    it "properly handles all support lookup record types" do
      movie_relationships = {
        cast_members: cast_members,
        creators: creators,
        directors: directors,
        genres: genres,
        keywords: keywords
      }
      movie_relationships.each do |relationship_name, expected_names|
        results = ImdbParser.find_or_create_lookup_records(relationship_name, movie_attrs)
        expect(results.count).to eq(expected_names.count)
        results.each { |lookup_record| expect(expected_names).to include(lookup_record.name) }
      end
    end
  end

  describe ".movies" do
    before do
      @movie1 = Movie.create!(name: "Test Movie 1")
      @movie2 = Movie.create!(name: "Test Movie 2")
      @movie3 = Movie.create!(name: "Test Movie 3")
    end

    it "fetches the full list of movies when initially called" do
      expect(Movie).to receive(:all).and_return([@movie1, @movie2, @movie3])
      expect(ImdbParser.movies).to eq(
        "Test Movie 1" => @movie1,
        "Test Movie 2" => @movie2,
        "Test Movie 3" => @movie3
      )
    end

    it "does NOT re-fetch movies after the first call" do
      ImdbParser.movies
      expect(Movie).not_to receive(:all)
      expect(ImdbParser.movies).to eq(
        "Test Movie 1" => @movie1,
        "Test Movie 2" => @movie2,
        "Test Movie 3" => @movie3
      )
    end
  end

  describe ".genres" do
    before do
      @genre1 = Genre.create!(name: "Genre 1", tag: "genre_1")
      @genre2 = Genre.create!(name: "Genre 2", tag: "genre_2")
      @genre3 = Genre.create!(name: "Genre 3", tag: "genre_3")
    end

    it "fetches the full list of genres when initially called" do
      expect(Genre).to receive(:all).and_return([@genre1, @genre2, @genre3])
      expect(ImdbParser.genres).to eq(
        "genre_1" => @genre1,
        "genre_2" => @genre2,
        "genre_3" => @genre3
      )
    end

    it "does NOT re-fetch genres after the first call" do
      ImdbParser.genres
      expect(Genre).not_to receive(:all)
      expect(ImdbParser.genres).to eq(
        "genre_1" => @genre1,
        "genre_2" => @genre2,
        "genre_3" => @genre3
      )
    end
  end
end
