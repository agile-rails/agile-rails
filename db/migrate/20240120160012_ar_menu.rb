class ArMenu < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_menus do |t|
      t.string  :name
      t.string  :description
      t.string  :div_name
      t.boolean :link_name
      t.string  :css
      t.boolean :active, default: true
      t.integer :ar_site_id

      t.timestamps
      t.integer :created_by
      t.integer :updated_by

      t.index :name, :unique=>true
      t.index :ar_site_id
    end

  end
end
