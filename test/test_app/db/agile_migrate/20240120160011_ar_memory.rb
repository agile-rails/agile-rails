class ArMemory < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_memories do |t|
      t.string :data
    end

  end
end
