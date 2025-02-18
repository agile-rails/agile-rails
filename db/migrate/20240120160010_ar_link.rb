class ArLink < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_links do |t|
      t.string  :link
      t.string  :params
      t.boolean :active, default: true
      t.string  :redirect
      t.integer :page_id
      t.integer :ar_site_id

      t.integer :created_by
      t.integer :updated_by
      t.timestamps

      t.index [:ar_site_id, :link], :unique => true
    end

  end
end
