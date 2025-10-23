module Api
  module V1
    class PersonasController < ApplicationController
      before_action :authenticate_user!
      before_action :underscore_params!, only: %i[create update]
      before_action :set_persona, only: %i[show update destroy]

      # GET /api/personas
      def index
        @personas = current_user.personas

        # Responder con formato JSON:API
        render json: {
          data: @personas.map do |persona|
            {
              id: persona.id.to_s,
              type: 'personas',
              attributes: persona.as_json(
                except: %i[id created_at updated_at]
              ).merge(
                created_at: persona.created_at.iso8601,
                updated_at: persona.updated_at.iso8601
              )
            }
          end
        }
      end

      # GET /api/personas/:id
      def show
        # Responder con formato JSON:API
        render json: {
          data: {
            id: @persona.id.to_s,
            type: 'personas',
            attributes: @persona.as_json(
              except: %i[id created_at updated_at]
            ).merge(
              created_at: @persona.created_at.iso8601,
              updated_at: @persona.updated_at.iso8601
            )
          }
        }
      end

      # POST /api/personas
      def create
        # Support payloads sent either as { persona: { ... } } or top-level keys
        @persona = current_user.personas.build(persona_params)

        # Depurar los parámetros recibidos
        Rails.logger.debug "Params: #{params.inspect}"
        Rails.logger.debug "Persona params: #{persona_params.inspect}"
        Rails.logger.debug "Tipo persona: #{@persona.tipo_persona.inspect}"

        if @persona.save
          handle_certificates

          # Responder con formato JSON:API
          render json: {
            data: {
              id: @persona.id.to_s,
              type: 'personas',
              attributes: @persona.as_json(
                except: %i[id created_at updated_at]
              ).merge(
                created_at: @persona.created_at.iso8601,
                updated_at: @persona.updated_at.iso8601
              )
            }
          }, status: :created
        else
          Rails.logger.error "Validation errors: #{@persona.errors.full_messages}"
          render json: { errors: @persona.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/personas/:id
      def update
        if @persona.update(persona_params)
          handle_certificates

          # Responder con formato JSON:API
          render json: {
            data: {
              id: @persona.id.to_s,
              type: 'personas',
              attributes: @persona.as_json(
                except: %i[id created_at updated_at]
              ).merge(
                created_at: @persona.created_at.iso8601,
                updated_at: @persona.updated_at.iso8601
              )
            }
          }
        else
          render json: { errors: @persona.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/personas/:id
      def destroy
        @persona.destroy
        head :no_content
      end

      # GET /api/personas/rfc/:rfc
      def find_by_rfc
        rfc = params[:rfc]
        @persona = Persona.find_by(rfc: rfc)

        # Si encontramos la persona en la tabla Persona
        if @persona
          render json: {
            success: true,
            client_data: {
              tin: @persona.rfc,
              legalName: @persona.razon_social,
              zipCode: @persona.codigo_postal,
              taxRegimeCode: @persona.regimen_fiscal,
              cfdiUseCode: @persona.uso_cfdi,
              email: @persona.email
            }
          }
        else
          # Si no la encontramos en Persona, buscar en Invoice (para compatibilidad)
          invoice = Invoice.where(rfc: rfc).order(created_at: :desc).first
          
          if invoice && invoice.body.present? && invoice.body["serviceRequest"].present? &&
             invoice.body["serviceRequest"]["recipient"].present?
            
            recipient = invoice.body["serviceRequest"]["recipient"]
            
            # También crear un registro en Persona para futuras búsquedas
            begin
              Persona.create!(
                rfc: rfc,
                razon_social: recipient["legalName"],
                email: recipient["email"],
                tipo_persona: rfc.length == 12 ? "MORAL" : "FISICA", # Determinar tipo de persona basado en longitud del RFC
                codigo_postal: recipient["zipCode"],
                regimen_fiscal: recipient["taxRegimeCode"],
                uso_cfdi: recipient["cfdiUseCode"],
                user_id: invoice.user_id || User.first.id # Usar el user_id de la factura o el primer usuario
              )
              Rails.logger.info("Persona creada desde factura para RFC: #{rfc}")
            rescue => e
              Rails.logger.error("Error al crear persona desde factura: #{e.message}")
            end
            
            # Devolver los datos encontrados en la factura
            render json: {
              success: true,
              client_data: {
                tin: recipient["tin"],
                legalName: recipient["legalName"],
                zipCode: recipient["zipCode"],
                taxRegimeCode: recipient["taxRegimeCode"],
                cfdiUseCode: recipient["cfdiUseCode"],
                email: recipient["email"]
              }
            }
          else
            # No se encontró en ninguna tabla
            render json: { 
              success: false, 
              message: "No se encontró ningún cliente con el RFC: #{rfc}"
            }, status: :ok  # Mantenemos el status 200 para evitar interrupciones en el frontend
          end
        end
      end

      private

      def set_persona
        @persona = current_user.personas.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Persona no encontrada' }, status: :not_found
      end

      def persona_params
        base = if params[:persona].present?
                 params.require(:persona)
               else
                 # allow top-level keys
                 params
               end

        base.permit(
          :razon_social,
          :regimen_capital,
          :email,
          :tipo_persona,
          :rfc,
          :regimen_fiscal,
          :uso_cfdi,
          :codigo_postal,
          :contrasena_sellos,
          :curp,
          :certificado_cer,
          :certificado_key
        )
      end

      def handle_certificates
        # Manejar la subida de archivos de certificados si están presentes
        cer_param = params.dig(:persona, :certificado_cer) || params[:certificado_cer]
        key_param = params.dig(:persona, :certificado_key) || params[:certificado_key]

        @persona.certificado_cer.attach(cer_param) if cer_param.present?

        return unless key_param.present?

        @persona.certificado_key.attach(key_param)
      end

      # Convert incoming param keys from camelCase to snake_case recursively
      def underscore_params!
        # Only transform JSON / Hash-like params
        return unless params.respond_to?(:deep_transform_keys!)

        params.deep_transform_keys!(&:underscore)
      end
    end
  end
end
