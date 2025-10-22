class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users, id: :uuid do |t|
      ## Tenant
      t.references :account, type: :uuid, null: false, foreign_key: true

      ## Profile
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.boolean :admin, null: false, default: false
      t.boolean :active, null: false, default: true

      ## Business counters
      t.integer :invoices_count, null: false, default: 0

      ## Devise defaults
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email

      ## JWT revocation strategy (optional: jti)
      t.string :jti, null: false

      t.timestamps null: false
    end

    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :confirmation_token,   unique: true
    add_index :users, :jti, unique: true
  end
end
