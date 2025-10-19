# app/controllers/api/v1/auth/registrations_controller.rb
class Api::V1::Auth::RegistrationsController < Devise::RegistrationsController
  respond_to :json
  skip_before_action :authenticate_user!, only: [ :create ]
  skip_before_action :set_current_account, only: [ :create ]
  # Vamos a autenticar manualmente en el método update
  skip_before_action :authenticate_user!, only: [ :update ]
  skip_before_action :set_current_account, only: [ :update ]

  def create
    ActsAsTenant.without_tenant do
      User.load_schema
      Rails.logger.info "Creamos al usuario con los parametros: #{params.inspect}"

      # 👇 Extrae correctamente los parámetros anidados
      user_params = params.require(:user).permit(
        :email, :password, :password_confirmation,
        :first_name, :last_name, :phone,
        :state, :company_name
      )

      user = User.new(user_params.merge(
        account_id: nil,
        admin: true,
        active: true,
        subscribed: true
      ))

      if user.save
        Rails.logger.info "✅ Usuario creado exitosamente: #{user.inspect}"
        render json: { message: "Usuario creado", user: user_serializer(user) }, status: :created
      else
        Rails.logger.error "❌ Error al crear usuario: #{user.errors.full_messages}"
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end


  # TODO: Implementar la actualización del usuario
  def update
    user = current_user
    return render_unauthorized("No autenticado") unless user

    raw = params[:user].is_a?(ActionController::Parameters) ? params[:user] : params
    pw_params = raw.slice(:current_password, :password, :password_confirmation).to_unsafe_h.compact_blank
    profile_params = raw.slice(:first_name, :last_name, :phone, :company_name, :state).to_unsafe_h.compact_blank
    
    # Handle letterhead upload if present
    letterhead_file = raw[:letterhead]
    
    if pw_params.blank? && profile_params.blank? && letterhead_file.blank?
      return render_unprocessable("Nada para actualizar")
    end

    # Update profile parameters
    if profile_params.present?
      unless user.update(profile_params)
        return render_errors(user)
      end
    end

    # Update password if provided
    if pw_params.present?
      if pw_params[:current_password].blank?
        return render_unprocessable("current_password es requerido para cambiar la contraseña")
      end

      unless user.update_with_password(pw_params)
        # Devise llenará user.errors con mensajes útiles
        return render_errors(user)
      end
    end
    
    # Attach letterhead file if present
    if letterhead_file.present?
      begin
        user.letterhead.attach(letterhead_file)
        user.update(letterhead_filename: letterhead_file.original_filename)
        Rails.logger.info "✅ Plantilla de hoja membretada actualizada: #{letterhead_file.original_filename}"
      rescue => e
        Rails.logger.error "❌ Error al adjuntar hoja membretada: #{e.message}"
        return render json: { error: "Error al subir la hoja membretada: #{e.message}" }, status: :unprocessable_entity
      end
    end

    render json: { message: "Usuario actualizado", user: user_serializer(user) }, status: :ok
  end

  def destroy
    user = current_user
    return render json: { error: "No autenticado" }, status: :unauthorized unless user

    current_password = params[:current_password]
    unless user.valid_password?(current_password)
      return render json: { error: "Contraseña incorrecta" }, status: :unauthorized
    end

    if user.destroy
      render json: { message: "Cuenta eliminada correctamente" }, status: :ok
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def render_errors(resource)
    render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
  end

  def render_unprocessable(msg)
    render json: { error: msg }, status: :unprocessable_entity
  end

  def render_unauthorized(msg)
    render json: { error: msg }, status: :unauthorized
  end

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation,
      :first_name, :last_name, :company_name)
  end

  def account_update_params
    # Aceptamos los parámetros directamente o dentro de un objeto user o registration
    permitted_params = [ :email, :current_password, :password, :password_confirmation,
      :first_name, :last_name, :phone, :company_name ]

    if params[:user].present?
      params.require(:user).permit(permitted_params)
    elsif params[:registration].present?
      params.require(:registration).permit(permitted_params)
    else
      params.permit(permitted_params)
    end
  end

  def user_serializer(user)
    letterhead_data = nil
    
    if user.letterhead.attached?
      letterhead_data = {
        filename: user.letterhead.filename.to_s,
        content_type: user.letterhead.content_type,
        url: Rails.application.routes.url_helpers.rails_blob_url(user.letterhead, only_path: true)
      }
    end
    
    {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      full_name: user.full_name,
      phone: user.phone,
      admin: user.admin,
      account_id: user.account_id,
      state: user.state,
      company_name: user.company_name,
      letterhead: letterhead_data
    }
  end
end
