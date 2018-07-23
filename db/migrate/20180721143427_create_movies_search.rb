class CreateMoviesSearch < ActiveRecord::Migration[5.2]
  def up
    # Sets up a full-text search compatible table.
    execute <<-SQL
      CREATE VIRTUAL TABLE movies_search
        USING FTS4(
          id UNINDEXED,
          search_content
        );
    SQL
  end

  def down
    drop_table :movies_search
  end
end
