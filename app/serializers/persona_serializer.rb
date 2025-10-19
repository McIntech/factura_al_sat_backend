class PersonaSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :razon_social, :regimen_capital, :email, :tipo_persona, :rfc,
             :regimen_fiscal, :uso_cfdi, :codigo_postal, :curp, :created_at, :updated_at,
             :certificado_cer_url, :certificado_key_url

  # No enviamos la contraseña de sellos en las respuestas por seguridad

  def certificado_cer_url
    object.certificado_cer.attached? ? rails_blob_url(object.certificado_cer) : nil
  end

  def certificado_key_url
    object.certificado_key.attached? ? rails_blob_url(object.certificado_key) : nil
  end
end
