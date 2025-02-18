class ArBigTableValue < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_big_table_values do |t|
      t.integer :ar_big_table_id
      t.string  :value
      t.string  :description
      t.string  :locales
      t.boolean :active, default: true
      t.integer :created_by
      t.integer :updated_by

      t.timestamps

      t.index :ar_big_table_id, name: 'bt_by_ar_big_table_id'
    end

  end
end
