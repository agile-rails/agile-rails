class ArImage < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_images do |t|
      t.string  :name
      t.string  :img_type
      t.string  :text
      t.string  :short
      t.boolean :keep_original, default: false
      t.string  :size_o
      t.string  :size_l
      t.string  :size_m
      t.string  :size_s
      t.integer :page_id
      t.string  :keywords

      t.integer :ar_site_id
      t.integer :created_by
      t.timestamps

      t.index :ar_site_id
      t.index :created_by
    end

  end
end
