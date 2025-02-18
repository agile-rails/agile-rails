class ArRole < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_roles do |t|
      t.string  :name
      t.string  :system_name
      t.boolean :active, default: true

      t.timestamps
      t.integer :created_by
      t.integer :updated_by

      t.index :name, :unique=>true
      t.index :system_name
    end

  end
end
