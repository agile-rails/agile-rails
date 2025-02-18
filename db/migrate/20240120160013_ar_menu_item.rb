class ArMenuItem < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_menu_items do |t|
      t.string  :caption
      t.string  :link
      t.string  :picture
      t.integer :page_id
      t.text    :content
      t.string  :clas
      t.string  :link_to
      t.string  :target
      t.integer :order,  default: 0
      t.boolean :active, default: true
      t.boolean :hidden, default: false
      t.boolean :prepend_path, default: true
      t.integer :policy_id
      t.integer :parent_id, default: 0
      t.integer :created_by
      t.integer :updated_by

      t.integer :ar_menu_id
      t.timestamps

      t.index :ar_menu_id
    end

  end
end
