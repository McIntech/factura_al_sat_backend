class Persona < ApplicationRecord
  belongs_to :user
  before_validation :normalize_tipo_persona
  # --- 📋 Validaciones ---
  validates :razon_social, :email, :tipo_persona, :rfc, :regimen_fiscal, :uso_cfdi, :codigo_postal, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :codigo_postal, format: { with: /\A\d{5}\z/, message: 'debe tener exactamente 5 dígitos' }
  validates :tipo_persona,
            inclusion: {
              in: %w[FISICA MORAL],
              message: 'debe ser FISICA o MORAL'
            }
  # Atributos para almacenar los certificados
  has_one_attached :certificado_cer
  has_one_attached :certificado_key

  private

  def normalize_tipo_persona
    self.tipo_persona = tipo_persona&.strip&.upcase if tipo_persona.present?
  end
end
