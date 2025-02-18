class ArPermission < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_permissions do |t|
      t.string :table_name
      t.boolean :is_default
      t.boolean :active, default: true

      t.timestamps
      t.integer :created_by
      t.integer :updated_by

      t.index :table_name, unique: true
    end

  end
end
