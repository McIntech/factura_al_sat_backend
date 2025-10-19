class Persona < ApplicationRecord
  belongs_to :user

  # --- 📋 Validaciones ---
  validates :razon_social, :email, :tipo_persona, :rfc, :regimen_fiscal, :uso_cfdi, :codigo_postal, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :codigo_postal, format: { with: /\A\d{5}\z/, message: "debe tener exactamente 5 dígitos" }
  validates :tipo_persona, inclusion: { in: [ "Persona Física", "Persona Moral", "fisica", "moral" ] }

  # Atributos para almacenar los certificados
  has_one_attached :certificado_cer
  has_one_attached :certificado_key
end
