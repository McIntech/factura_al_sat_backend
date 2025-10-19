class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts, id: :uuid do |t|
      t.string :name, null: false
      t.integer :organization_people_count, null: false, default: 0
      t.timestamps
    end
  end
end
