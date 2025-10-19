class AddUserIdToInvoices < ActiveRecord::Migration[8.0]
  def change
    # Permitimos que user_id sea nulo para soportar facturas sin usuario (códigos de servicio)
    add_reference :invoices, :user, null: true, foreign_key: true
  end
end
