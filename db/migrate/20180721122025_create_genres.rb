class CreateGenres < ActiveRecord::Migration[5.2]
  def change
    create_table :genres do |t|
      t.string :name, null: false
      t.string :tag, null: false, unique: true
      t.timestamps
      t.index [:tag]
    end

    create_table :movies_genres do |t|
      t.references :movie
      t.references :genre
    end
  end
end
