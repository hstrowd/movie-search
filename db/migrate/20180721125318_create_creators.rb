class CreateCreators < ActiveRecord::Migration[5.2]
  def change
    create_table :creators do |t|
      t.string :name, null: false
      t.string :tag, null: false, unique: true
      t.timestamps
      t.index [:tag]
    end

    create_table :movies_creators do |t|
      t.references :movie
      t.references :creator
    end
  end
end
