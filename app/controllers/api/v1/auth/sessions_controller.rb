class Api::V1::Auth::SessionsController < Devise::SessionsController
  include ActionController::MimeResponds
  respond_to :json
  skip_before_action :authenticate_user!, only: [:create]
  skip_before_action :verify_signed_out_user, only: [:destroy]

  # === LOGIN ===
  def create
    user_params = params[:user].presence || params
    email = user_params[:email]
    password = user_params[:password]
    if email.blank? || password.blank?
      return render json: { status: { code: 400, message: 'Faltan credenciales' } },
                    status: :bad_request
    end

    ActsAsTenant.without_tenant do
      user = User.find_by(email: email)
      unless user&.valid_password?(password)
        return render json: { status: { code: 401, message: 'Credenciales inválidas' } }, status: :unauthorized
      end

      user.update!(jti: SecureRandom.uuid) if user.jti.blank?
      token = JWT.encode(
        {
          sub: user.id.to_s,
          scp: 'user',
          iat: Time.now.to_i,
          exp: Time.now.to_i + 2.hours.to_i,
          jti: user.jti
        },
        ENV.fetch('DEVISE_JWT_SECRET_KEY'),
        'HS256'
      )

      render json: {
        status: { code: 200, message: 'Inicio de sesión exitoso.' },
        data: { user: user, token: token }
      }, status: :ok
    end
  end

  # === LOGOUT ===
  def destroy
    auth_header = request.headers['Authorization']
    unless auth_header&.start_with?('Bearer ')
      return render json: { status: { code: 401, message: 'No se proporcionó un token válido' } },
                    status: :unauthorized
    end

    token = auth_header.split.last
    begin
      payload = JWT.decode(token, ENV.fetch('DEVISE_JWT_SECRET_KEY'), true, { algorithm: 'HS256' }).first
      ActsAsTenant.without_tenant do
        user = User.find(payload['sub'])
        user.update!(jti: SecureRandom.uuid)
      end
      render json: { status: { code: 200, message: 'Sesión cerrada.' } }, status: :ok
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render json: { status: { code: 401, message: 'Token inválido o usuario no encontrado' } }, status: :unauthorized
    end
  end
end
