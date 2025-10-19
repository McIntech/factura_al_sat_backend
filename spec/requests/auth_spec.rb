require 'rails_helper'

RSpec.describe "Authentication", type: :request do
  let(:devise_jwt_secret) { ENV.fetch("DEVISE_JWT_SECRET_KEY", "test_secret_key_for_jwt") }

  describe "Registro de usuario (POST /api/v1/auth/sign_up)" do
    let(:valid_attributes) do
      {
        user: {
          company_name: "Mi Empresa Test",
          email: "test@example.com",
          password: "password123",
          password_confirmation: "password123",
          first_name: "Juan",
          last_name: "Pérez"
        }
      }
    end

    context 'cuando los parámetros son válidos' do
      it 'crea un nuevo Account y User administrador' do
        without_tenant do
          expect {
            post "/api/v1/auth/sign_up", params: valid_attributes
          }.to change(Account, :count).by(1)
            .and change(User, :count).by(1)

          expect(response).to have_http_status(:created)

          json = JSON.parse(response.body)
          expect(json["user"]).to include("id", "email", "account_id")
          expect(json["user"]["email"]).to eq("test@example.com")

          # Verificar que el usuario creado es admin
          user = User.find(json["user"]["id"])
          expect(user.admin).to be true

          # Verificar que pertenece al account creado
          account = Account.find(json["user"]["account_id"])
          expect(account.name).to eq("Mi Empresa Test")
          expect(user.account).to eq(account)
        end
      end
    end

    context 'cuando los parámetros son inválidos' do
      let(:invalid_attributes) do
        {
          user: {
            email: "invalid-email",
            password: "short",
            password_confirmation: "nomatch",
            first_name: "",
            last_name: ""
          }
        }
      end

      it 'no crea un nuevo usuario ni account' do
        without_tenant do
          expect {
            post "/api/v1/auth/sign_up", params: invalid_attributes
          }.to change(Account, :count).by(0)
            .and change(User, :count).by(0)

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe "Login (POST /api/v1/auth/sign_in)" do
    let!(:account) { create(:account) }
    let!(:user) do
      with_tenant(account) do
        create(:user, :admin, account: account, email: "admin@example.com", password: "password123")
      end
    end
    before do
      ActsAsTenant.current_tenant = account
    end

    context 'cuando las credenciales son correctas y el usuario está activo' do
      it 'devuelve un JWT token en el header' do
        post "/api/v1/auth/sign_in", params: {
          user: { email: "admin@example.com", password: "password123" }
        }

        expect(response).to have_http_status(:ok)
        expect(response.headers["Authorization"]).to be_present

        # Verificar que el token es válido
        token = response.headers["Authorization"].split(" ").last
        decoded_token = JWT.decode(token, devise_jwt_secret, true, { algorithm: 'HS256' })
        expect(decoded_token[0]["sub"]).to eq(user.id)
        expect(decoded_token[0]["jti"]).to eq(user.jti)

        # Verificar la respuesta JSON
        json = JSON.parse(response.body)
        expect(json["user"]).to include(
          "id", "email", "name", "admin", "account_id"
        )
        expect(json["user"]["email"]).to eq("admin@example.com")
        expect(json["user"]["admin"]).to be true
      end
    end

    context 'cuando las credenciales son incorrectas' do
      it 'devuelve error de autenticación' do
        post "/api/v1/auth/sign_in", params: {
          user: { email: "admin@example.com", password: "wrong_password" }
        }

        expect(response).to have_http_status(:unauthorized)
        expect(response.headers["Authorization"]).to be_nil
      end
    end

    context 'cuando el usuario está inactivo' do
      let!(:inactive_user) { create(:user, :inactive, account: account, email: "inactive@example.com", password: "password123") }

      it 'devuelve error de cuenta inactiva' do
        post "/api/v1/auth/sign_in", params: {
          user: { email: "inactive@example.com", password: "password123" }
        }

        expect(response).to have_http_status(:forbidden)
        expect(response.headers["Authorization"]).to be_nil

        json = JSON.parse(response.body)
        expect(json["error"]).to eq("inactive_account")
      end
    end
  end

  describe "Acceso a rutas protegidas" do
    let!(:account) { create(:account) }
    let!(:user) do
      with_tenant(account) do
        create(:user, account: account)
      end
    end

    context 'con JWT válido' do
      it 'permite acceder a rutas protegidas' do
        get "/api/v1/auth/validate_token", headers: auth_headers_for(user)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["status"]["message"]).to eq("Token válido")
        expect(json["data"]["user"]["id"]).to eq(user.id)
      end
    end

    context 'sin JWT' do
      it 'rechaza el acceso a rutas protegidas' do
        get "/api/v1/auth/validate_token"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'con JWT inválido' do
      it 'rechaza el acceso a rutas protegidas' do
        headers = { 'Authorization': "Bearer invalid.token.here" }
        get "/api/v1/auth/validate_token", headers: headers

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "Logout (DELETE /api/v1/auth/sign_out)" do
    let!(:account) { create(:account) }
    let!(:user) do
      with_tenant(account) do
        create(:user, account: account)
      end
    end

    it 'revoca el token JWT del usuario' do
      # Guardar el jti original
      original_jti = user.jti

      # Hacer logout
      delete "/api/v1/auth/sign_out", headers: auth_headers_for(user)

      # Verificar que la respuesta es correcta
      expect(response).to have_http_status(:no_content)

      # Verificar que el jti fue cambiado
      user.reload
      expect(user.jti).not_to eq(original_jti)

      # Intentar usar el token anterior debe fallar
      get "/api/v1/auth/validate_token", headers: auth_headers_for(user)
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
