# frozen_string_literal: true

class ImdbParser
  BASE_URL = "https://www.imdb.com"
  TOP_1000_LIST_URL = "#{BASE_URL}/search/title?groups=top_1000"

  def self.load_list(url:, page: 1)
    full_url = HttpClient.construct_url(url, page: page)
    return unless full_url

    Rails.logger.info("Loading IMDB movies from #{full_url}")
    html_page = HttpClient.fetch_page(full_url)
    return unless html_page

    parse_movie_list(html_page)

    next_page_link = html_page.css("#main .lister .nav .lister-page-next.next-page")[0]
    load_list(url: url, page: page + 1) if next_page_link
  end

  def self.parse_movie_list(html_page)
    movies = html_page.css("#main .lister .lister-list .lister-item")
    Rails.logger.info("Processing #{movies.count} movies.")

    parsed_movies = movies.collect do |movie_html|
      movie_attrs = extract_movie_overview(movie_html)
      next if movie_attrs.blank?
      movie_attrs = fetch_movie_details(movie_attrs)
      add_or_update_movie(movie_attrs)
    end

    Rails.logger.info("Processed #{movies.count} movies.")
    parsed_movies.compact
  end

  def self.extract_movie_overview(movie_html)
    movie_attrs = {}

    return if movie_html.css(".lister-item-header a")[0].blank?

    movie_attrs[:name] = movie_html.css(".lister-item-header a")[0].text
    url_path = movie_html.css(".lister-item-header a")[0]["href"]
    movie_attrs[:imdb_url] = /imdb.com/i.match?(url_path) ? url_path : "#{BASE_URL}#{url_path}"
    rank = movie_html.css(".lister-item-header .lister-item-index")[0]&.text
    movie_attrs[:imdb_rank] = rank && rank[0..-2].delete(",") # Drop the trailing '.' and any commas
    movie_attrs[:rating] = movie_html.css(".certificate")[0]&.text
    duration_extract = movie_html.css(".runtime")[0]&.text&.match(/(\d.*) min/)
    movie_attrs[:duration] = duration_extract[1].to_i if duration_extract
    movie_attrs[:genres] = movie_html.css(".genre")[0]&.text&.split(",")&.map(&:strip) || []

    movie_attrs
  end

  def self.fetch_movie_details(movie_attrs)
    return movie_attrs unless movie_attrs[:imdb_url]

    Rails.logger.info("Fetching details for #{movie_attrs[:name]}")
    movie_details_html = HttpClient.fetch_page(movie_attrs[:imdb_url])

    movie_attrs[:brief_description] = movie_details_html.css("#main_top .summary_text")[0]&.text&.strip
    release_date = movie_details_html.css("#main_top meta[itemprop='datePublished']")[0]
    movie_attrs[:release_date] = release_date && release_date["content"]
    movie_attrs[:imdb_stars] = movie_details_html.css("#main_top .ratingValue [itemprop='ratingValue']")[0]&.text
    movie_attrs[:directors] = movie_details_html.css("#main_top .credit_summary_item [itemprop='director'] [itemprop='name']").map(&:text)
    movie_attrs[:creators] = movie_details_html.css("#main_top .credit_summary_item [itemprop='creator'] [itemprop='name']").map(&:text)
    movie_attrs[:cast_members] = movie_details_html.css("#main_bottom .cast_list [itemprop='actor'] [itemprop='name']").map(&:text)
    movie_attrs[:keywords] = movie_details_html.css("#main_bottom .article a [itemprop='keywords']").map(&:text)

    movie_attrs
  end

  def self.add_or_update_movie(movie_attrs)
    return unless movie_attrs[:name]

    movie = movies[movie_attrs[:name]] || Movie.new(name: movie_attrs[:name])

    movie_attrs[:cast_members] = find_or_create_lookup_records(:cast_members, movie_attrs)
    movie_attrs[:creators] = find_or_create_lookup_records(:creators, movie_attrs)
    movie_attrs[:directors] = find_or_create_lookup_records(:directors, movie_attrs)
    movie_attrs[:genres] = find_or_create_lookup_records(:genres, movie_attrs)
    movie_attrs[:keywords] = find_or_create_lookup_records(:keywords, movie_attrs)

    unless movie.update(movie_attrs)
      Rails.logger.warn("Failed to save/update '#{movie.name}'.\n  Details: #{movie_attrs}\n  Errors:  #{movie.errors}")
      return
    end

    movie.update_search
    movies[movie.name] = movie
  end

  def self.find_or_create_lookup_records(relationship, movie_attrs)
    unless respond_to?(relationship)
      Rails.logger.warn("Unrecognized movie relationship: #{relationship}")
      return []
    end
    lookup_record_collection = send(relationship)

    model_name = relationship.to_s.classify
    begin
      lookup_record_model = model_name.constantize
    rescue NameError
      Rails.logger.warn("Unable to find model for movie relationship #{relationship}. Expected #{model_name} model to exist.")
      return []
    end

    (movie_attrs[relationship] || []).collect do |lookup_record_name|
      next lookup_record_collection[lookup_record_name.parameterize] if lookup_record_collection[lookup_record_name.parameterize]
      lookup_record = lookup_record_model.create!(tag: lookup_record_name.parameterize, name: lookup_record_name)
      lookup_record_collection[lookup_record.tag] = lookup_record
    end.compact
  end

  def self.cast_members
    @cast_members ||= CastMember.all.map { |cast_member| [cast_member.tag, cast_member] }.to_h
  end

  def self.creators
    @creators ||= Creator.all.map { |creator| [creator.tag, creator] }.to_h
  end

  def self.directors
    @directors ||= Director.all.map { |director| [director.tag, director] }.to_h
  end

  def self.genres
    @genres ||= Genre.all.map { |genre| [genre.tag, genre] }.to_h
  end

  def self.keywords
    @keywords ||= Keyword.all.map { |keyword| [keyword.tag, keyword] }.to_h
  end

  def self.movies
    @movies ||= Movie.all.map { |movie| [movie.name, movie] }.to_h
  end
end
