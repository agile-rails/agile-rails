class ArPage < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_pages do |t|
      t.string :subject, default: ''
      t.string :link, default: ''
      t.string :alt_link, default: ''
      t.string :sub_subject, default: ''
      t.string :picture
      t.boolean :gallery
      t.string :body, default: ''
      t.string :css, default: ''
      t.string :script, default: ''
      t.string :params
      t.string :div_class
      t.string :menu_id
      t.integer :author_id
      t.string :author_name
      t.integer :ar_poll_id
      t.datetime :publish_date
      t.string :user_name
      t.datetime :valid_from
      t.datetime :valid_to
      t.boolean :comments, default: true
      t.boolean :active, default: true
      t.string  :if_url
      t.integer :if_border, default: 0
      t.integer :if_width
      t.integer :if_height
      t.string  :if_scroll
      t.string  :if_id
      t.string  :if_class
      t.string  :if_params
      t.string  :title
      t.string  :meta_description
      t.string  :canonical_link
      t.integer :policy_id
      t.integer :ar_site_id
      t.integer :ar_design_id

      t.timestamps
      t.integer :created_by
      t.integer :updated_by

      t.index :ar_site_id
      t.index :link
      t.index :alt_link
    end

  end
end
