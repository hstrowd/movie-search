# frozen_string_literal: true

require "rails_helper"

RSpec.describe "load:imdb_top_1000" do
  it "triggers the IMDB top 1000 movies to be loaded into the DB" do
    expect(ImdbParser).to receive(:load_list).with(url: /groups=top_1000/i)
    expect { task.execute }.not_to raise_error
  end
end
