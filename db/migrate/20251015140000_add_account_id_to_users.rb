class AddAccountIdToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :account, type: :uuid, null: false, foreign_key: true
  end
end
