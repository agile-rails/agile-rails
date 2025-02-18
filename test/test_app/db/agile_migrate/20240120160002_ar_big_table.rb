class ArBigTable < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_big_tables do |t|
      t.string  :key
      t.string  :description
      t.integer :site_id
      t.boolean :active, default: true
      t.integer :created_by
      t.integer :updated_by

      t.timestamps

      t.index [:key, :site_id]
    end

  end
end
