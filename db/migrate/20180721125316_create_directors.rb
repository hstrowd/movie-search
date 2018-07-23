class CreateDirectors < ActiveRecord::Migration[5.2]
  def change
    create_table :directors do |t|
      t.string :name, null: false
      t.string :tag, null: false, unique: true
      t.timestamps
      t.index [:tag]
    end

    create_table :movies_directors do |t|
      t.references :movie
      t.references :director
    end
  end
end
