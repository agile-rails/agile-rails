class ArGallery < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_galleries do |t|
      t.string  :title
      t.string  :description
      t.string  :picture
      t.string  :thumbnail
      t.integer :doc_id
      t.string  :doc_type
      t.integer :order, default: 10
      t.boolean :active, default: true

      t.integer :created_by
      t.integer :updated_by
      t.timestamps

      t.index [:doc_type, :doc_id]
    end

  end
end
