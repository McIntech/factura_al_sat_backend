class Api::V1::InvoiceMailerController < ApplicationController
  before_action :authenticate_user!
  
  # POST /api/v1/invoices/send_email
  # Recibe un PDF en base64 y lo envía por correo electrónico
  def send_email
    # Log incoming parameters for debugging
    Rails.logger.info("Invoice email request: #{params.except(:pdf_data).inspect}")
    Rails.logger.info("Has recipient data: #{params[:recipient_email].present?}")
    
    # Validar parámetros requeridos
    unless params[:pdf_data].present? && params[:recipient_email].present?
      render json: { success: false, error: 'Se requieren los campos pdf_data y recipient_email' }, status: :unprocessable_entity
      return
    end
    
    begin
      # Preparar datos para el registro
      invoice_id = params[:invoice_id] || SecureRandom.uuid
      recipient_email = params[:recipient_email].strip
      pdf_data = params[:pdf_data] # Base64 encoded PDF
      
      # Optional params
      invoice_number = params[:invoice_number] || invoice_id
      sender_name = params[:sender_name] || current_user&.name || 'Sistema de Facturación'
      company_name = params[:company_name] || current_user&.company_name || 'FiscalAPI'
      
      # Verify PDF data format
      unless pdf_data.present? && pdf_data.is_a?(String)
        render json: { success: false, error: 'El formato del PDF es inválido' }, status: :unprocessable_entity
        return
      end
      
      # Verify PDF is properly base64 encoded - remove any data URI prefix
      if pdf_data.start_with?('data:')
        pdf_data = pdf_data.split(',').last
      end
      
      begin
        # Validate base64 format
        Base64.strict_decode64(pdf_data)
      rescue ArgumentError => e
        render json: { success: false, error: "El PDF no está correctamente codificado en base64: #{e.message}" }, status: :unprocessable_entity
        return
      end
      
      # Create or update invoice record if needed
      Invoice.find_or_create_by(code: invoice_id) do |i|
        i.recipient_email = recipient_email
        i.user = current_user
      end
      
      # Send email with the PDF using our mailer
      begin
        Rails.logger.info("Sending invoice #{invoice_number} to #{recipient_email}")
        
        InvoiceMailer.send_invoice(
          recipient_email, 
          pdf_data, 
          invoice_id: invoice_id,
          invoice_number: invoice_number,
          sender_name: sender_name,
          company_name: company_name
        ).deliver_now
        
        # Generate unique message ID
        message_id = "#{Time.now.to_i}-#{SecureRandom.hex(8)}@#{request.host}"
        
        # Return success response
        render json: {
          success: true,
          status: 'sent',
          uuid: invoice_id,
          sent_to: recipient_email,
          message_id: message_id
        }, status: :ok
      rescue Net::SMTPError => e
        Rails.logger.error("SMTP Error: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        render json: { success: false, error: "Error de SMTP: #{e.message}" }, status: :service_unavailable
      rescue Net::ProtocolError => e
        Rails.logger.error("Protocol Error: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        render json: { success: false, error: "Error de protocolo: #{e.message}" }, status: :service_unavailable
      end
    rescue => e
      Rails.logger.error("Error al enviar factura por correo: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      render json: { success: false, error: "Error al procesar el envío: #{e.message}" }, status: :internal_server_error
    end
  end
end