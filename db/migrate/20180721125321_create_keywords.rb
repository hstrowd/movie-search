class CreateKeywords < ActiveRecord::Migration[5.2]
  def change
    create_table :keywords do |t|
      t.string :name, null: false
      t.string :tag, null: false, unique: true
      t.timestamps
      t.index [:tag]
    end

    create_table :movies_keywords do |t|
      t.references :movie
      t.references :keyword
    end
  end
end
