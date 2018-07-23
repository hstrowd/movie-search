class CreateMovies < ActiveRecord::Migration[5.2]
  def change
    create_table :movies do |t|
      t.string :name, null: false
      t.text :brief_description
      t.date :release_date
      t.integer :duration
      t.string :rating
      t.string :imdb_url
      t.integer :imdb_rank
      t.float :imdb_stars

      t.timestamps
    end
  end
end
