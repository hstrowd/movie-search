# frozen_string_literal: true

namespace :load do
  desc "Load the moves from the IMDB top 1000 list"
  task imdb_top_1000: :environment do
    ImdbParser.load_list(url: ImdbParser::TOP_1000_LIST_URL)
  end
end
