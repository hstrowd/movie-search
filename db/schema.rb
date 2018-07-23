# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_07_21_143427) do

  create_table "cast_members", force: :cascade do |t|
    t.string "name", null: false
    t.string "tag", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag"], name: "index_cast_members_on_tag"
  end

  create_table "creators", force: :cascade do |t|
    t.string "name", null: false
    t.string "tag", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag"], name: "index_creators_on_tag"
  end

  create_table "directors", force: :cascade do |t|
    t.string "name", null: false
    t.string "tag", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag"], name: "index_directors_on_tag"
  end

  create_table "genres", force: :cascade do |t|
    t.string "name", null: false
    t.string "tag", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag"], name: "index_genres_on_tag"
  end

  create_table "keywords", force: :cascade do |t|
    t.string "name", null: false
    t.string "tag", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag"], name: "index_keywords_on_tag"
  end

  create_table "movies", force: :cascade do |t|
    t.string "name", null: false
    t.text "brief_description"
    t.date "release_date"
    t.integer "duration"
    t.string "rating"
    t.string "imdb_url"
    t.integer "imdb_rank"
    t.float "imdb_stars"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "movies_cast_members", force: :cascade do |t|
    t.integer "movie_id"
    t.integer "cast_member_id"
    t.index ["cast_member_id"], name: "index_movies_cast_members_on_cast_member_id"
    t.index ["movie_id"], name: "index_movies_cast_members_on_movie_id"
  end

  create_table "movies_creators", force: :cascade do |t|
    t.integer "movie_id"
    t.integer "creator_id"
    t.index ["creator_id"], name: "index_movies_creators_on_creator_id"
    t.index ["movie_id"], name: "index_movies_creators_on_movie_id"
  end

  create_table "movies_directors", force: :cascade do |t|
    t.integer "movie_id"
    t.integer "director_id"
    t.index ["director_id"], name: "index_movies_directors_on_director_id"
    t.index ["movie_id"], name: "index_movies_directors_on_movie_id"
  end

  create_table "movies_genres", force: :cascade do |t|
    t.integer "movie_id"
    t.integer "genre_id"
    t.index ["genre_id"], name: "index_movies_genres_on_genre_id"
    t.index ["movie_id"], name: "index_movies_genres_on_movie_id"
  end

  create_table "movies_keywords", force: :cascade do |t|
    t.integer "movie_id"
    t.integer "keyword_id"
    t.index ["keyword_id"], name: "index_movies_keywords_on_keyword_id"
    t.index ["movie_id"], name: "index_movies_keywords_on_movie_id"
  end

# Could not dump table "movies_search" because of following StandardError
#   Unknown type '' for column 'id'

# Could not dump table "movies_search_content" because of following StandardError
#   Unknown type '' for column 'c0id'

  create_table "movies_search_docsize", primary_key: "docid", force: :cascade do |t|
    t.binary "size"
  end

  create_table "movies_search_segdir", primary_key: ["level", "idx"], force: :cascade do |t|
    t.integer "level"
    t.integer "idx"
    t.integer "start_block"
    t.integer "leaves_end_block"
    t.integer "end_block"
    t.binary "root"
    t.index ["level", "idx"], name: "sqlite_autoindex_movies_search_segdir_1", unique: true
  end

  create_table "movies_search_segments", primary_key: "blockid", force: :cascade do |t|
    t.binary "block"
  end

  create_table "movies_search_stat", force: :cascade do |t|
    t.binary "value"
  end

end
