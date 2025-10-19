class InvoiceMailer < ApplicationMailer
  default from: ENV['EMAIL'] || 'noreply@fiscalapi.com'

  def send_invoice(recipient_email, pdf_data, options = {})
    Rails.logger.info("InvoiceMailer.send_invoice to: #{recipient_email}, options: #{options.inspect}")
    
    @invoice_id = options[:invoice_id] || 'N/A'
    @invoice_number = options[:invoice_number] || @invoice_id
    @sender_name = options[:sender_name] || 'Sistema de Facturación'
    @company_name = options[:company_name] || 'FiscalAPI'
    @recipient_email = recipient_email
    
    begin
      # Ensure pdf_data is properly base64 encoded
      if pdf_data.is_a?(String) && !pdf_data.empty?
        # Create PDF attachment from base64 data
        pdf_content = Base64.decode64(pdf_data)
        
        # Make sure the PDF is valid and has proper content
        if pdf_content.length < 100 # Arbitrary small size check
          Rails.logger.error("PDF data seems too small (#{pdf_content.length} bytes)")
        end
        
        attachments["factura-#{@invoice_number}.pdf"] = {
          mime_type: 'application/pdf',
          content: pdf_content
        }
        
        mail(
          to: recipient_email,
          subject: "Factura #{@invoice_number} - #{@company_name}"
        )
      else
        Rails.logger.error("Invalid PDF data provided: #{pdf_data.class}, length: #{pdf_data&.length}")
        raise ArgumentError, "Invalid PDF data provided"
      end
    rescue => e
      Rails.logger.error("Error in InvoiceMailer: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      raise e # Re-raise to be caught by the controller
    end
  end
end