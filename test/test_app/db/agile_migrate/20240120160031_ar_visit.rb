class ArVisit < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_visits do |t|
      t.integer :page_id
      t.integer :user_id
      t.integer :site_id
      t.string :session_id
      t.string :ip
      t.datetime :time

      t.index :time
    end

  end
end
