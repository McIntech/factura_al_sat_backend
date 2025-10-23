class Api::V1::Auth::RegistrationsController < Devise::RegistrationsController
  respond_to :json
  skip_before_action :authenticate_user!, only: [:create]
  skip_before_action :set_current_account, only: [:create]

  def create
    ActsAsTenant.without_tenant do
      user_params = params.require(:user).permit(:email, :password, :first_name, :last_name, :phone, :state,
                                                 :company_name)
      user = User.new(user_params.merge(admin: true, active: true, subscribed: true))
      if user.save
        render json: { message: 'Usuario creado', user: user }, status: :created
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  def destroy
    user = current_user
    return render json: { error: 'No autenticado' }, status: :unauthorized unless user

    current_password = params[:current_password]
    unless user.valid_password?(current_password)
      return render json: { error: 'Contraseña incorrecta' }, status: :unauthorized
    end

    if user.destroy
      render json: { status: { code: 200, message: 'Cuenta eliminada correctamente' } }, status: :ok
    else
      render json: { status: { code: 422, message: 'Error al eliminar cuenta' }, errors: user.errors.full_messages },
             status: :unprocessable_entity
    end
  end

  def update
    user = current_user
    return render json: { error: 'No autenticado' }, status: :unauthorized unless user

    raw = params[:user].is_a?(ActionController::Parameters) ? params[:user] : params
    pw_params = raw.slice(:current_password, :password, :password_confirmation).to_unsafe_h.compact_blank
    profile_params = raw.slice(:first_name, :last_name, :phone, :company_name, :state).to_unsafe_h.compact_blank

    if pw_params.blank?
      if user.update(profile_params)
        return render json: { message: 'Usuario actualizado', user: user_serializer(user) }, status: :ok
      end

      return render json: { errors: user.errors.full_messages }, status: :unprocessable_entity

    end

    if pw_params[:current_password].blank?
      return render json: { errors: { current_password: ["can't be blank"] } }, status: :unprocessable_entity
    end

    unless user.update_with_password(pw_params)
      return render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end

    render json: { message: 'Usuario actualizado', user: user_serializer(user) }, status: :ok
  end

  private

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
