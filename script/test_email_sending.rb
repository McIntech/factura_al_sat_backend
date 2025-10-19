#!/usr/bin/env ruby
# Este script prueba si el remitente tiene algún problema
# Uso: rails runner script/test_email_sending.rb

require 'mail'

# Configura Mail
smtp_settings = Rails.application.config.action_mailer.smtp_settings
Mail.defaults do
  delivery_method :smtp, smtp_settings
end

sender = ENV.fetch('EMAIL', 'soporte@cuiker.com')
test_subject = "Prueba de envío #{Time.now.strftime('%H:%M:%S')}"

# Envía un correo al mismo remitente
begin
  puts "Enviando correo de prueba de #{sender} a sí mismo..."
  
  mail = Mail.new do
    from    sender
    to      sender
    subject test_subject
    body    "Este es un correo de auto-prueba para verificar si el remitente #{sender} puede recibir correos."
  end
  
  mail.deliver!
  puts "✅ Correo enviado correctamente a #{sender}"
  puts "Por favor verifica si el correo con asunto '#{test_subject}' llega a #{sender}"
  puts "Si el correo llega al remitente pero no a tu dirección, es probable que haya un problema de filtrado o spam en tu cuenta."
rescue => e
  puts "❌ Error al enviar el correo: #{e.message}"
  puts "Esto sugiere que hay un problema con la cuenta remitente."
end