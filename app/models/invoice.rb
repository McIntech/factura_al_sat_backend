class Invoice < ApplicationRecord
  # Hacemos que la asociación con user sea opcional para soportar el caso de IDs de servicio
  belongs_to :user, optional: true
  
  # Adjuntos para el XML y PDF de la factura
  has_one_attached :pdf
  has_one_attached :xml
  
  # Para registrar los envíos de email de facturas
  has_many :email_logs, as: :loggable, dependent: :destroy
  
  # Almacena los datos de la factura como JSON
  store :data, accessors: [
    :versionCode, :series, :date, :paymentFormCode, 
    :paymentMethodCode, :currencyCode, :typeCode, 
    :expeditionZipCode, :exchangeRate, :exportCode,
    :issuer, :recipient, :items
  ], coder: JSON
  
  # Aseguramos un UUID único para cada factura
  before_create :set_uuid
  # Número se maneja a través del código en el controlador
  
  # Validaciones
  validates :series, presence: true
  
  # Búsqueda por código
  scope :search_by_code, ->(code) {
    if code.present?
      where(code: code)
    else
      all
    end
  }
  
  # Buscar por RFC
  scope :search_by_rfc, ->(rfc) {
    if rfc.present?
      where("recipient ->> 'tin' = ?", rfc)
    else
      none
    end
  }
  
  # Calcular el total de la factura
  def total
    return 0 if items.blank?
    
    items.sum do |item|
      subtotal = item[:quantity].to_f * item[:unitPrice].to_f
      discount = item[:discount].to_f
      subtotal - discount
    end
  end
  
  # Calcular los impuestos de la factura
  def taxes
    return 0 if items.blank?
    
    items.sum do |item|
      subtotal = item[:quantity].to_f * item[:unitPrice].to_f
      discount = item[:discount].to_f
      net_amount = subtotal - discount
      
      if item[:itemTaxes].present?
        item[:itemTaxes].sum do |tax|
          net_amount * tax[:taxRate].to_f
        end
      else
        0
      end
    end
  end
  
  # Calcular el total con impuestos
  def total_with_taxes
    total + taxes
  end
  
  private
  
  # Generar un UUID para la factura
  def set_uuid
    self.invoice_id ||= SecureRandom.uuid
  end
  
  # Este método ya no se utiliza ya que no existe la columna number
  # y el código se establece en el controlador
  # def set_number
  #   last_number = Invoice.where(series: self.series).maximum(:code) || 0
  # end
end
