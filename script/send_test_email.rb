#!/usr/bin/env ruby
# Este script envía un correo electrónico de prueba para verificar la configuración SMTP
# Uso: rails runner script/send_test_email.rb destinatario@ejemplo.com

require 'mail'

# Verifica que se proporcionó un destinatario
if ARGV.empty?
  puts "Por favor proporciona una dirección de correo electrónico."
  puts "Uso: rails runner script/send_test_email.rb destinatario@ejemplo.com"
  exit
end

recipient = ARGV[0]

# Muestra la configuración actual de SMTP
smtp_settings = Rails.application.config.action_mailer.smtp_settings
puts "Configuración SMTP actual:"
puts smtp_settings.except(:password).inspect
puts "\nIntentando enviar correo electrónico a #{recipient}..."

begin
  # Intenta enviar correo con ActionMailer
  mail = InvoiceMailer.send_invoice(
    recipient, 
    "JVBERi0xLjMKJf", # Datos mínimos de PDF en base64
    invoice_id: "TEST-#{Time.now.to_i}",
    invoice_number: "TEST-#{Time.now.to_i}",
    sender_name: "Prueba SMTP",
    company_name: "FiscalAPI"
  )
  
  puts "Correo enviado correctamente con ActionMailer"
  puts "De: #{mail.from}"
  puts "Para: #{mail.to}"
  puts "Asunto: #{mail.subject}"
  puts "\nCorreo enviado. Verifica tu bandeja de entrada (incluyendo carpetas de spam)."
  
rescue => e
  puts "Error al enviar correo con ActionMailer: #{e.message}"
  puts e.backtrace.join("\n")
  
  # Intenta con la gema Mail directamente como alternativa
  puts "\nIntentando con la gema Mail directamente..."
  
  begin
    Mail.defaults do
      delivery_method :smtp, smtp_settings
    end
    
    mail = Mail.new do
      from     ENV.fetch('EMAIL', 'soporte@cuiker.com')
      to       recipient
      subject  'Correo de prueba - FiscalAPI'
      body     'Este es un correo de prueba para verificar la configuración SMTP.'
    end
    
    mail.delivery_method.settings.merge!(smtp_settings)
    mail.deliver!
    puts "Correo enviado correctamente con la gema Mail"
  rescue => e2
    puts "Error al enviar correo con la gema Mail: #{e2.message}"
    puts e2.backtrace.join("\n")
    puts "\nSugerencias de solución:"
    puts "1. Verifica que el servidor SMTP (#{smtp_settings[:address]}) es correcto"
    puts "2. Verifica que el puerto (#{smtp_settings[:port]}) está abierto"
    puts "3. Verifica que el nombre de usuario (#{smtp_settings[:user_name]}) es correcto"
    puts "4. Asegúrate que la contraseña proporcionada es una contraseña de aplicación válida para Gmail"
    puts "5. Verifica que la cuenta no tenga autenticación de dos factores o que estás usando una contraseña de aplicación"
    puts "6. Revisa si Gmail está bloqueando el acceso por 'aplicaciones menos seguras'"
  end
end