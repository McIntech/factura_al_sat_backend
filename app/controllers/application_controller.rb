# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  include Pundit::Authorization
  set_current_tenant_through_filter

  before_action :log_auth_headers
  before_action :authenticate_user!
  before_action :set_current_account
  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from Pundit::NotAuthorizedError do
    render json: { error: "forbidden" }, status: :forbidden
  end

  rescue_from ActionController::ParameterMissing do |e|
    render json: { error: e.message }, status: :unprocessable_entity
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name, :company_name ])
  end

  private

  def log_auth_headers
    Rails.logger.info "=" * 80
    Rails.logger.info "🔍 Request: #{request.method} #{request.path}"
    Rails.logger.info "Authorization header: #{request.headers['Authorization']}"
    Rails.logger.info "HTTP_AUTHORIZATION: #{request.headers['HTTP_AUTHORIZATION']}"
    Rails.logger.info "=" * 80
  end

  def set_current_account
    return unless current_user
    begin
      # Intentamos configurar el tenant solo si el usuario tiene un account
      if current_user.account.present?
        set_current_tenant(current_user.account)
      else
        # Para endpoints públicos o endpoints que no requieren tenant
        ActsAsTenant.current_tenant = nil
      end
    rescue ActsAsTenant::Errors::NoTenantSet
      # En caso de error, simplemente continuamos sin configurar tenant
      Rails.logger.debug "No tenant set for user #{current_user.id}"
    end
  end

  # Método para usar en endpoints que no requieren tenant
  def skip_tenant_handling
    ActsAsTenant.without_tenant do
      yield
    end
  end
end
