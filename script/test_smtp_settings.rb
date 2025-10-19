#!/usr/bin/env ruby
# Este script realiza pruebas exhaustivas de envío de correo electrónico
# Uso: rails runner script/test_smtp_settings.rb destinatario@ejemplo.com

require 'mail'
require 'net/smtp'

# Verifica que se proporcionó un destinatario
if ARGV.empty?
  puts "Por favor proporciona una dirección de correo electrónico."
  puts "Uso: rails runner script/test_smtp_settings.rb destinatario@ejemplo.com"
  exit
end

recipient = ARGV[0]
sender_email = ENV.fetch('EMAIL', 'soporte@cuiker.com')
email_password = ENV.fetch('EMAIL_APP_PASSWORD', ENV.fetch('EMAIL_PASSWORD', nil))

puts "=== Verificación de configuración SMTP ==="
puts "Email remitente: #{sender_email}"
puts "Contraseña configurada: #{email_password ? 'Sí (longitud: ' + email_password.length.to_s + ')' : 'No'}"

# Obtener la configuración SMTP
smtp_settings = Rails.application.config.action_mailer.smtp_settings
puts "\n=== Configuración SMTP actual ==="
puts smtp_settings.except(:password).inspect

# Prueba 1: Conexión básica SMTP
puts "\n=== Prueba 1: Conexión básica SMTP ==="
begin
  Net::SMTP.start(
    smtp_settings[:address],
    smtp_settings[:port],
    smtp_settings[:domain],
    smtp_settings[:user_name],
    smtp_settings[:password],
    smtp_settings[:authentication]
  ) do |smtp|
    puts "✅ Conexión SMTP establecida correctamente"
  end
rescue => e
  puts "❌ Error de conexión SMTP: #{e.message}"
  puts "   #{e.backtrace.first}"
end

# Prueba 2: Envío directo con Net::SMTP
puts "\n=== Prueba 2: Envío directo con Net::SMTP ==="
begin
  message = <<MESSAGE_END
From: #{sender_email}
To: #{recipient}
Subject: Prueba SMTP directa - FiscalAPI

Este es un correo de prueba enviado directamente con Net::SMTP.
MESSAGE_END

  Net::SMTP.start(
    smtp_settings[:address],
    smtp_settings[:port],
    smtp_settings[:domain],
    smtp_settings[:user_name],
    smtp_settings[:password],
    smtp_settings[:authentication]
  ) do |smtp|
    smtp.send_message message, sender_email, recipient
  end
  puts "✅ Correo enviado correctamente con Net::SMTP"
rescue => e
  puts "❌ Error al enviar con Net::SMTP: #{e.message}"
  puts "   #{e.backtrace.first}"
end

# Prueba 3: Envío con la gema Mail
puts "\n=== Prueba 3: Envío con la gema Mail ==="
begin
  Mail.defaults do
    delivery_method :smtp, smtp_settings
  end
  
  mail = Mail.new do
    from    sender_email
    to      recipient
    subject 'Prueba con la gema Mail - FiscalAPI'
    body    'Este es un correo de prueba enviado con la gema Mail.'
  end
  
  mail.deliver!
  puts "✅ Correo enviado correctamente con la gema Mail"
rescue => e
  puts "❌ Error al enviar con la gema Mail: #{e.message}"
  puts "   #{e.backtrace.first}"
end

# Prueba 4: Envío con ActionMailer
puts "\n=== Prueba 4: Envío con ActionMailer ==="
begin
  mail = InvoiceMailer.send_invoice(
    recipient, 
    "JVBERi0xLjMKJf", # Datos mínimos de PDF en base64
    invoice_id: "TEST-#{Time.now.to_i}",
    invoice_number: "TEST-#{Time.now.to_i}",
    sender_name: "Prueba SMTP",
    company_name: "FiscalAPI"
  ).deliver_now
  
  puts "✅ Correo enviado correctamente con ActionMailer"
  puts "   De: #{mail.from}"
  puts "   Para: #{mail.to}"
  puts "   Asunto: #{mail.subject}"
rescue => e
  puts "❌ Error al enviar con ActionMailer: #{e.message}"
  puts "   #{e.backtrace.first}"
end

puts "\n=== Recomendaciones para Gmail ==="
puts "1. Verifica que estás usando una contraseña de aplicación (no tu contraseña regular)"
puts "2. Asegúrate que la cuenta de Gmail no tiene restricciones de seguridad adicionales"
puts "3. Revisa las carpetas de spam, promociones, social, etc. en tu bandeja de Gmail"
puts "4. Si ninguna prueba funcionó, intenta habilitar 'Acceso de apps menos seguras' temporalmente"
puts "   en https://myaccount.google.com/security"
puts ""
puts "Si las pruebas fueron exitosas pero no recibes los correos, revisa filtros o reglas de correo."