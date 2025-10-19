class Api::V1::AuthController < ApplicationController
  include UserSerialization
  before_action :authenticate_user!, only: [ :validate_token ]
  before_action :log_request_headers, only: [ :validate_token ]

  # Validar token
  def validate_token
    render json: {
      status: { code: 200, message: "Token válido" },
      data: {
        user: serialize_user(current_user)
      }
    }
  end

  private

  def log_request_headers
    Rails.logger.info "=" * 80
    Rails.logger.info "🔍 Headers recibidos en validate_token:"
    Rails.logger.info "Authorization: #{request.headers['Authorization']}"
    Rails.logger.info "HTTP_AUTHORIZATION: #{request.headers['HTTP_AUTHORIZATION']}"
    Rails.logger.info "All headers: #{request.headers.to_h.select { |k, _| k.match?(/AUTH|TOKEN/i) }}"
    Rails.logger.info "=" * 80
  end
end
