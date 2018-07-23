class CreateCastMembers < ActiveRecord::Migration[5.2]
  def change
    create_table :cast_members do |t|
      t.string :name, null: false
      t.string :tag, null: false, unique: true
      t.timestamps
      t.index [:tag]
    end

    create_table :movies_cast_members do |t|
      t.references :movie
      t.references :cast_member
    end
  end
end
