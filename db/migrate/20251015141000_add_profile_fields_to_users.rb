class AddProfileFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :first_name, :string, null: false
    add_column :users, :last_name, :string, null: false
    add_column :users, :admin, :boolean, null: false, default: false
    add_column :users, :active, :boolean, null: false, default: true
    add_column :users, :invoices_count, :integer, null: false, default: 0
    add_column :users, :confirmed_at, :datetime
    add_column :users, :jti, :string, null: false
  end
end
