class AddFieldsToInvoices < ActiveRecord::Migration[8.0]
  def change
    # Campos mínimos necesarios para manejar facturas externas
    add_column :invoices, :invoice_id, :string  # ID de la factura en FiscalAPI
    add_column :invoices, :recipient_email, :string  # Email del destinatario
    add_column :invoices, :fiscal_response, :jsonb, default: {}  # Para guardar la respuesta de FiscalAPI
    add_column :invoices, :status, :string, default: 'sent'  # Estado del envío del email

    # Mantenemos la referencia al usuario que envió la factura
    unless column_exists?(:invoices, :user_id)
      add_reference :invoices, :user, foreign_key: true, null: true
    end

    # Índices para búsquedas rápidas
    add_index :invoices, :invoice_id
    add_index :invoices, :recipient_email

    # No renombramos las columnas existentes para mantener total compatibilidad
  end
end
