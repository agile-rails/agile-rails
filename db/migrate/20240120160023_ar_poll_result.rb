class ArPollResult < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_poll_results do |t|
      t.integer :ar_poll_id
      t.string  :data
      t.boolean :confirmed

      t.timestamps

      t.index :ar_poll_id
    end

  end
end
