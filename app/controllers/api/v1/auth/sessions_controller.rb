# app/controllers/api/v1/auth/sessions_controller.rb
class Api::V1::Auth::SessionsController < Devise::SessionsController
  include ActionController::MimeResponds
  include UserSerialization
  respond_to :json
  skip_before_action :authenticate_user!, only: [ :create ]
  skip_before_action :set_current_account, only: [ :create ]
  skip_before_action :verify_signed_out_user, only: [ :destroy ]

  def create
    Rails.logger.info "Intento de inicio de sesión con params: #{params.inspect}"

    # 👇 Lee correctamente desde params[:user] o plano
    user_params = params[:user].presence || params
    email       = user_params[:email]
    password    = user_params[:password]

    if email.blank? || password.blank?
      return render json: { status: { code: 400, message: "Faltan credenciales" } }, status: :bad_request
    end

    ActsAsTenant.without_tenant do
      user = User.find_by(email: email)

      if user&.valid_password?(password)
        # Garantiza que tenga un JTI asignado
        user.update!(jti: SecureRandom.uuid) if user.jti.blank?

        secret_key = ENV.fetch("DEVISE_JWT_SECRET_KEY")
        expiration = 2.hours.to_i

        payload = {
          sub: user.id.to_s,
          scp: "user",
          aud: nil,
          iat: Time.now.to_i,
          exp: Time.now.to_i + expiration,
          jti: user.jti
        }

        token = JWT.encode(payload, secret_key, "HS256")

        Rails.logger.info "✅ LOGIN: Token generado con JTI=#{user.jti} para usuario=#{user.id}"
        response.set_header("Authorization", "Bearer #{token}")

        render json: {
          status: { code: 200, message: "Inicio de sesión exitoso." },
          data: { user: serialize_user(user), token: token }
        }, status: :ok
      else
        Rails.logger.warn "❌ LOGIN FALLIDO para #{email}"
        render json: {
          status: { code: 401, message: "Credenciales inválidas" },
          error: "Correo o contraseña incorrectos"
        }, status: :unauthorized
      end
    end
  end


  def destroy
    Rails.logger.info "Intento de cierre de sesión"
    # Manejamos el logout como una operación stateless
    # Extraemos el token del header de Authorization
    auth_header = request.headers["Authorization"]

    if auth_header && auth_header.start_with?("Bearer ")
      token = auth_header.split(" ").last

      begin
        payload = JWT.decode(token, ENV.fetch("DEVISE_JWT_SECRET_KEY"), true, { algorithm: "HS256" }).first
        user_id = payload["sub"]

        # Revocamos el token rotando el JTI
        ActsAsTenant.without_tenant do
          user = User.find(user_id)
          user.update!(jti: SecureRandom.uuid)
          render json: { status: { code: 200, message: "Sesión cerrada." } }, status: :ok
        end
      rescue JWT::DecodeError
        render json: { status: { code: 401, message: "Token inválido" } }, status: :unauthorized
      rescue ActiveRecord::RecordNotFound
        render json: { status: { code: 401, message: "Usuario no encontrado" } }, status: :unauthorized
      end
    else
      render json: { status: { code: 401, message: "No se proporcionó un token válido" } }, status: :unauthorized
    end
  end

  private

  def serialize_user(user)
    user_data = {
      id: user.id,
      email: user.email,
      name: user.full_name,
      admin: user.admin,
      account_id: user.account_id,
      first_name: user.first_name,
      last_name: user.last_name
    }
    
    # Añadir información de la hoja membretada si existe
    if user.letterhead.attached?
      user_data[:letterhead] = {
        filename: user.letterhead.filename.to_s,
        url: Rails.application.routes.url_helpers.rails_blob_path(user.letterhead, only_path: true)
      }
      user_data[:letterhead_filename] = user.letterhead.filename.to_s
    end
    
    user_data
  end
end
