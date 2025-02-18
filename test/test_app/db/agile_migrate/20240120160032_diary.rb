class Diary < ActiveRecord::Migration[7.0]
  def change
    create_table :diaries do |t|
      t.string :title
      t.string :body
      t.datetime :time_begin
      t.integer :duration
      t.string :search
      t.boolean :closed, default: true
      t.integer :user_id

      t.timestamps

      t.index :user_id
    end

  end
end
