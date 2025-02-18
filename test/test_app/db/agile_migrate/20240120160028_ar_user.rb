class ArUser < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_users do |t|
      t.string :username, default: ''
      t.string :title, default: ''
      t.string :first_name, default: ''
      t.string :middle_name, default: ''
      t.string :last_name, default: ''
      t.string :name
      t.string :company, default: ''
      t.string :address
      t.string :post
      t.string :country
      t.string :phone
      t.string :email
      t.string :www
      t.string :picture
      t.date   :birthdate
      t.string :about
      t.datetime :last_visit
      t.boolean :active, default: true
      t.date    :valid_from
      t.date    :valid_to
      t.boolean :group,  default: false
      t.string  :signature
      t.string  :interests
      t.string  :job_occup
      t.string  :description
      t.date    :reg_date
      t.string :password_digest

      t.timestamps
      t.integer :created_by
      t.integer :updated_by

      t.index :username, unique: true
      t.index :email, unique: true
      t.index :group
    end

  end
end
