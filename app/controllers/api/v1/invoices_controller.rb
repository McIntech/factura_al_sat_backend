class Api::V1::InvoicesController < ApplicationController
  # Skip authentication for public endpoints
  skip_before_action :authenticate_user!, only: [:find_by_rfc, :show_by_code, :create]
  
  def index
  end

  def find_by_rfc
    # Obtener el RFC de los parámetros
    rfc = params[:rfc]
    Rails.logger.info("Buscando cliente con RFC: #{rfc}")

    # Buscar la última factura con ese RFC para obtener los datos del cliente
    invoice = Invoice.where(rfc: rfc).order(created_at: :desc).first

    if invoice && invoice.body.present? && invoice.body["serviceRequest"].present? &&
       invoice.body["serviceRequest"]["recipient"].present?

      recipient_data = invoice.body["serviceRequest"]["recipient"]

      Rails.logger.info("Cliente encontrado con RFC: #{rfc}")
      render json: {
        success: true,
        message: "Cliente encontrado con éxito",
        client_data: recipient_data
      }, status: :ok
    else
      Rails.logger.warn("No se encontró ningún cliente con el RFC: #{rfc}")
      render json: {
        success: false,
        error: "No se encontró ningún cliente con el RFC: #{rfc}"
      }, status: :not_found
    end
  end

  def show_by_code
    # Asegurarse de que el parámetro code está presente
    code = params[:code]
    Rails.logger.info("Buscando factura con código: #{code}")

    # Buscar la factura en la base de datos
    invoice = Invoice.find_by(code: code)

    if invoice
      # Incluir más detalles en la respuesta para depuración
      Rails.logger.info("Factura encontrada con ID: #{invoice.id}")
      render json: {
        message: "Factura encontrada con éxito",
        invoice: invoice,
        code: invoice.code
      }, status: :ok
    else
      Rails.logger.warn("No se encontró ninguna factura con el código: #{code}")
      render json: { error: "Invoice not found with code: #{code}" }, status: :not_found
    end
  end

  def create
    # Generar código único para la factura
    code = "%06d" % rand(0..999999)

    # Extraer datos del recipient (si existen)
    recipient_data = params.dig(:serviceRequest, :recipient)

    # Verificamos si realmente hay datos del recipient (todos los campos están vacíos o no hay recipient)
    has_recipient_data = recipient_data.present? &&
                         (recipient_data[:tin].present? ||
                          recipient_data[:email].present? ||
                          recipient_data[:legalName].present? ||
                          recipient_data[:zipCode].present?)

    # Logging para debuggear
    Rails.logger.info("Recipient data: #{recipient_data.inspect}")
    Rails.logger.info("Has recipient data: #{has_recipient_data}")

    if has_recipient_data
      # Caso donde sí se proporcionó un recipient con datos
      rfc = recipient_data[:tin]
      email = recipient_data[:email]

      if rfc.blank?
        render json: { error: "RFC is required when recipient is provided" }, status: :unprocessable_entity
        return
      end

      # Buscar si existe una factura con ese RFC
      existing_invoice = Invoice.find_by(rfc: rfc)

      # Buscar o crear usuario asociado
      user = find_or_create_user_from_recipient(recipient_data)

      if existing_invoice
        # Actualizar factura existente
        existing_invoice.update(
          email: email,
          code: code.to_i,  # Asegurar que el código sea un entero
          body: params,
          user_id: user.id,
          series: params.dig(:serviceRequest, :series) || "F"  # Asegurar que series esté presente
        )
        render json: {
          message: "Invoice updated successfully",
          invoice: existing_invoice,
          code: code
        }, status: :ok
      else
        # Crear nueva factura
        invoice = Invoice.new(
          rfc: rfc,
          email: email,
          code: code.to_i,  # Asegurar que el código sea un entero
          body: params,
          user_id: user.id,
          series: params.dig(:serviceRequest, :series) || "F"  # Asegurar que series esté presente
        )

        if invoice.save
          render json: {
            message: "Invoice created successfully",
            invoice: invoice
          }, status: :created
        else
          render json: {
            error: "Failed to create invoice",
            errors: invoice.errors
          }, status: :unprocessable_entity
        end
      end
    else
      # Caso donde no se proporcionó recipient (generación de código de servicio)
      Rails.logger.info("Generando código de servicio sin usuario asociado")
      
      # Extraer series de los parámetros o usar un valor por defecto
      series = params.dig(:serviceRequest, :series) || "F"
      Rails.logger.info("Series para el código de servicio: #{series}")

      invoice = Invoice.new(
        rfc: "",
        email: "",
        code: code.to_i,  # Asegurar que el código sea un entero
        body: params,
        series: series,  # Agregamos explícitamente el campo series como un accessor
        # No se proporciona user_id para este caso
      )

      if invoice.save
        Rails.logger.info("Código de servicio generado correctamente: #{code}")
        render json: {
          message: "Service code generated successfully",
          invoice: invoice
        }, status: :created
      else
        Rails.logger.error("Error al guardar el código de servicio: #{invoice.errors.full_messages}")
        render json: {
          error: "Failed to generate service code",
          errors: invoice.errors
        }, status: :unprocessable_entity
      end
    end
  end

  private

  def find_or_create_user_from_recipient(recipient_data)
    # Buscar usuario por email en lugar de RFC
    email = recipient_data[:email]
    user = User.find_by(email: email)

    # Si no existe, crear nuevo usuario
    unless user
      user = User.new(
        email: email,
        phone: recipient_data[:phone].to_s,  # Asegurarse de que sea string incluso si es nil
        subscribed: false  # Valor por defecto, ajusta según tu lógica de negocio
      )
      user.save
    end

    user
  end
end
