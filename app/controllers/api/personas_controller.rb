module Api
  class PersonasController < ApplicationController
    before_action :authenticate_user!
    before_action :underscore_params!, only: [:create, :update]
    before_action :set_persona, only: [ :show, :update, :destroy ]

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
              except: [:id, :created_at, :updated_at]
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
            except: [:id, :created_at, :updated_at]
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
              except: [:id, :created_at, :updated_at]
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
              except: [:id, :created_at, :updated_at]
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

    private

    def set_persona
      @persona = current_user.personas.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Persona no encontrada" }, status: :not_found
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

      if cer_param.present?
        @persona.certificado_cer.attach(cer_param)
      end

      if key_param.present?
        @persona.certificado_key.attach(key_param)
      end
    end

    # Convert incoming param keys from camelCase to snake_case recursively
    def underscore_params!
      # Only transform JSON / Hash-like params
      if params.respond_to?(:deep_transform_keys!)
        params.deep_transform_keys!(&:underscore)
      end
    end
  end
end
