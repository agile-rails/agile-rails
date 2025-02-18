class ArKeyValueStore < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_key_value_stores do |t|
      t.string :key
      t.string :value

      t.index :key, unique: true
    end

  end
end
