class ArRemovedUrl < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_removed_urls do |t|
      t.string :url
      t.string :description
      t.integer :created_by
      t.integer :updated_by
      t.integer :ar_site_id

      t.timestamps

      t.index :ar_site_id
    end

  end
end
