class ArCategory < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_categories do |t|
      t.string  :name
      t.string  :description
      t.integer :ctype, default: 1
      t.integer :parent
      t.boolean :active, default: true
      t.integer :order, default: 0
      t.integer :created_by
      t.integer :updated_by
      t.integer :ar_site_id

      t.timestamps

      t.index :name
      t.index :ctype
      t.index :ar_site_id
    end

  end
end
