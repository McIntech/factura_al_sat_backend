class CreateInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices do |t|
      t.string :rfc
      t.string :email
      t.integer :code
      t.jsonb :body

      t.timestamps
    end
  end
end
