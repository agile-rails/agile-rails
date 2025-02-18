class ArPoll < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_polls do |t|
      t.string   :name, default: ''
      t.string   :title, default: ''
      t.string   :sub_text, default: ''
      t.string   :pre_display
      t.string   :operation
      t.string   :parameters
      t.string   :display, default: '1'
      t.string   :css
      t.string   :js
      t.string   :form
      t.datetime :valid_from
      t.datetime :valid_to
      t.string   :captcha_type
      t.boolean  :active, default: true

      t.integer  :created_by
      t.integer  :updated_by
      t.timestamps

      t.index :name, :unique=>true
    end

  end
end
