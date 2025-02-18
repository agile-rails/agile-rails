class ArFilter < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_filters do |t|
      t.integer :ar_user_id
      t.string  :table
      t.string  :description
      t.string  :filter, default: ''
      t.boolean :public
      t.boolean :active, default: true

      t.timestamps

      t.index [:table, :ar_user_id]
    end

  end
end
