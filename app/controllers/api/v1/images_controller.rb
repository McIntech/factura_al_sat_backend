require 'net/http'
require 'open-uri'

module Api
  module V1
    class ImagesController < ApplicationController
      skip_before_action :authenticate_user!, only: [:proxy]
      
      # GET /api/v1/images/proxy
      # Endpoint para servir imágenes con los headers CORS correctos
      # Uso: /api/v1/images/proxy?url=URL_ENCODED_ACTIVESTORAGE_URL
      def proxy
        url = params[:url]
        
        Rails.logger.info "⚙️ Solicitando proxy para imagen: #{url&.truncate(100)}"
        
        if url.blank?
          Rails.logger.error "❌ URL no proporcionada para proxy de imagen"
          return head :bad_request # Devuelve solo el código de estado sin HTML
        end
        
        begin
          # La URL ya viene codificada desde el cliente, no hacemos decode doble
          decoded_url = url
          
          # Validación básica de la URL para prevenir SSRF
          begin
            uri = URI.parse(decoded_url)
            # Validar que sea una URL interna o de dominio permitido
            unless ['localhost', '127.0.0.1'].include?(uri.host) || 
                  (uri.host == request.host) ||
                  (Rails.env.development? && uri.host.include?('localhost'))
              Rails.logger.error "⛔ Intento de acceso a host no permitido: #{uri.host}"
              return head :forbidden # 403 sin HTML
            end
          rescue URI::InvalidURIError => e
            Rails.logger.error "⛔ URL inválida: #{e.message}"
            return head :bad_request # 400 sin HTML
          end
          
          # Si es una URL de ActiveStorage, intentar resolver el blob directamente
          if decoded_url.include?('/rails/active_storage/')
            success = handle_activestorage_url(decoded_url)
            return if success # Si se manejó con éxito, ya se envió la respuesta
          end
          
          # Si llegamos aquí, intentar proxy directo
          Rails.logger.info "🌐 Usando proxy directo para URL: #{decoded_url.truncate(100)}"
          
          uri = URI.parse(decoded_url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = (uri.scheme == "https")
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?
          http.open_timeout = 5 # segundos
          http.read_timeout = 10 # segundos
          
          # Preparar el request preservando las cookies/headers originales para autenticación
          request = Net::HTTP::Get.new(uri.request_uri)
          
          # Reenviar cookies del navegador para mantener la sesión
          if cookies.present?
            request['Cookie'] = cookies.map { |k, v| "#{k}=#{v}" }.join('; ')
          end
          
          # Agregar otros headers importantes
          request['User-Agent'] = request.user_agent if request.user_agent
          request['Accept'] = 'image/*'
          request['X-Forwarded-For'] = request.ip if request.ip
          
          # Ejecutar el request
          response = http.request(request)
          
          if response.code == "200" && response['Content-Type'].to_s.include?('image/')
            # Enviar directamente los bytes de la imagen sin encapsular en HTML/JSON
            send_data response.body, 
                      type: response['Content-Type'], 
                      disposition: 'inline'
          else
            Rails.logger.error "❌ Error en proxy: #{response.code} - #{response.message}"
            Rails.logger.error "❌ Content-Type recibido: #{response['Content-Type']}"
            # Devolver error sin encapsular en HTML/JSON
            head :bad_gateway # 502 sin HTML
          end
          
        rescue StandardError => e
          Rails.logger.error "❌ Error procesando imagen: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          head :internal_server_error # 500 sin HTML
        end
      end
      
      private
      
      def handle_activestorage_url(url)
        Rails.logger.info "🔍 Analizando URL de ActiveStorage..."
        
        # Extraer el key del blob de la URL
        blob_key = extract_blob_key_from_url(url)
        
        if blob_key.present?
          Rails.logger.info "🔑 Blob key extraído: #{blob_key}"
          
          # Buscar el blob por su key
          begin
            blob = ActiveStorage::Blob.find_by(key: blob_key)
            
            if blob
              # Verificar que el blob no haya expirado (si tiene signed_id con tiempo)
              if blob.respond_to?(:signed_id) && 
                 url.include?(blob.signed_id) && 
                 !ActiveStorage.verifier.valid_message?(blob.signed_id)
                Rails.logger.error "⏰ URL de blob expirada"
                head :gone # 410 Gone, sin HTML
                return true
              end
              
              Rails.logger.info "✅ Blob encontrado, sirviendo imagen: #{blob.filename}"
              # Enviar los bytes directamente
              send_data blob.download, 
                        type: blob.content_type, 
                        disposition: 'inline',
                        filename: blob.filename.to_s
              return true
            else
              Rails.logger.error "⚠️ Blob no encontrado con key: #{blob_key}"
              head :not_found # 404 sin HTML
              return true
            end
          rescue ActiveStorage::FileNotFoundError => e
            Rails.logger.error "❌ Archivo no encontrado en storage: #{e.message}"
            head :not_found # 404 sin HTML
            return true
          rescue StandardError => e
            Rails.logger.error "❌ Error accediendo al blob: #{e.message}"
            return false # Continuar con el método proxy directo
          end
        end
        
        return false # No se pudo manejar como ActiveStorage
      end
      
      def extract_blob_key_from_url(url)
        # Estrategias para diferentes formatos de URL de ActiveStorage
        if url.include?('/rails/active_storage/disk/')
          # Formato: /rails/active_storage/disk/ID_ENCODED/filename
          match = url.match(/\/rails\/active_storage\/disk\/([^\/]+)\//)
          return match[1] if match
          
        elsif url.include?('/rails/active_storage/blobs/')
          # Varias formas posibles
          # Formato variante: /rails/active_storage/blobs/proxy/ID_ENCODED/filename
          variant_match = url.match(/\/rails\/active_storage\/blobs\/(?:proxy|redirect|variant)\/([^\/]+)\//)
          return variant_match[1] if variant_match
          
          # Formato estándar: /rails/active_storage/blobs/ID_ENCODED/KEY/filename
          standard_match = url.match(/\/rails\/active_storage\/blobs\/[^\/]+\/([^\/]+)\//)
          return standard_match[1] if standard_match
        end
        
        # Intentar buscar cualquier patrón que parezca un key de ActiveStorage
        # Los keys suelen ser strings de longitud específica, a veces con guiones
        generic_match = url.match(/\/([a-zA-Z0-9\-_]{20,})\//)
        return generic_match[1] if generic_match
        
        nil
      end
    end
  end
end