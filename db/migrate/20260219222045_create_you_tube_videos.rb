class CreateYouTubeVideos < ActiveRecord::Migration[8.1]
  def change
    create_table :youtube_videos do |t|
      t.string :url, null: false
      t.string :video_id, null: false
      t.string :title
      t.string :author_name
      t.text :thumbnail_url

      t.timestamps
    end

    add_index :youtube_videos, :url, unique: true
  end
end
