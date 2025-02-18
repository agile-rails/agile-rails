class ArTemp < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_temps do |t|
      t.string  :key
      t.boolean :active
      t.string  :data
      t.string  :order
    end

  end
end
