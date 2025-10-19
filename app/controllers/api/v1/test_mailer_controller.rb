class Api::V1::TestMailerController < ApplicationController
  # Skip authentication for testing
  skip_before_action :authenticate_user!, only: [:test_email]
  
  # GET /api/v1/test_email?email=your_email@example.com
  # Simple endpoint to test email sending
  def test_email
    recipient_email = params[:email]
    
    unless recipient_email.present?
      render json: { success: false, error: 'Email parameter required' }, status: :unprocessable_entity
      return
    end
    
    begin
      # Log SMTP settings for verification
      smtp_settings = Rails.application.config.action_mailer.smtp_settings
      Rails.logger.info("Testing email with SMTP settings: #{smtp_settings.except(:password).inspect}")
      
      # Send a simple test email
      InvoiceMailer.send_invoice(
        recipient_email, 
        File.read(Rails.root.join('test_data', 'test.pdf')) || "JVBERi0xLjMKJf", # Simple PDF data
        invoice_id: "TEST-#{Time.now.to_i}",
        invoice_number: "TEST-#{Time.now.to_i}",
        sender_name: "Test Sender",
        company_name: "Test Company"
      ).deliver_now
      
      render json: { 
        success: true,
        message: "Test email sent to #{recipient_email}",
        smtp: smtp_settings.except(:password)
      }
    rescue => e
      Rails.logger.error("Test email error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      
      render json: { 
        success: false, 
        error: "Test email failed: #{e.message}",
        smtp: smtp_settings.except(:password) 
      }, status: :internal_server_error
    end
  end
end