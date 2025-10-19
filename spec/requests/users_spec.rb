require 'rails_helper'

RSpec.describe "Gestión de Usuarios", type: :request do
  # Crear dos accounts para probar el aislamiento de tenants
  let!(:account1) { create(:account, name: "Empresa 1") }
  let!(:account2) { create(:account, name: "Empresa 2") }

  # Un admin y un usuario normal en account1
  let!(:admin1) { create(:user, :admin, account: account1, first_name: "Admin", last_name: "Uno") }
  let!(:user1) { create(:user, account: account1, first_name: "Usuario", last_name: "Normal") }

  # Un admin en account2
  let!(:admin2) { create(:user, :admin, account: account2, first_name: "Admin", last_name: "Dos") }

  describe "Admin crea un usuario en su tenant (POST /api/v1/users)" do
    let(:valid_attributes) do
      {
        user: {
          email: "nuevo@example.com",
          password: "password123",
          first_name: "Usuario",
          last_name: "Nuevo",
          admin: false,
          active: true
        }
      }
    end

    context 'cuando el usuario es admin' do
      it 'crea un nuevo usuario en su mismo account' do
        expect {
          post "/api/v1/users",
               params: valid_attributes,
               headers: auth_headers_for(admin1)
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)

        # Verificar que el usuario fue creado en el account correcto
        nuevo_user = User.find_by(email: "nuevo@example.com")
        expect(nuevo_user).to be_present
        expect(nuevo_user.account_id).to eq(account1.id)
        expect(nuevo_user.admin).to eq(false)
      end
    end

    context 'cuando el usuario no es admin' do
      it 'rechaza la creación con error de autorización' do
        expect {
          post "/api/v1/users",
               params: valid_attributes,
               headers: auth_headers_for(user1)
        }.not_to change(User, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "Listado de usuarios (GET /api/v1/users)" do
    context 'cuando el usuario es admin' do
      it 'devuelve solo los usuarios de su tenant' do
        get "/api/v1/users", headers: auth_headers_for(admin1)

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        user_ids = json.map { |u| u["id"] }

        # Debe incluir a los usuarios de account1
        expect(user_ids).to include(admin1.id)
        expect(user_ids).to include(user1.id)

        # No debe incluir usuarios de account2
        expect(user_ids).not_to include(admin2.id)

        # Verificar que se devuelven los campos esperados
        expect(json.first).to include("id", "email", "first_name", "last_name", "admin", "active", "account_id")
      end
    end

    context 'cuando el usuario no es admin' do
      it 'rechaza el acceso' do
        get "/api/v1/users", headers: auth_headers_for(user1)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "Admin desactiva otro usuario (PATCH /api/v1/users/:id)" do
    context 'cuando el usuario es admin' do
      it 'puede desactivar un usuario de su tenant' do
        patch "/api/v1/users/#{user1.id}",
              params: { user: { active: false } },
              headers: auth_headers_for(admin1)

        expect(response).to have_http_status(:ok)

        user1.reload
        expect(user1.active).to be false
      end

      it 'no puede desactivarse a sí mismo' do
        patch "/api/v1/users/#{admin1.id}",
              params: { user: { admin: false } },
              headers: auth_headers_for(admin1)

        expect(response).to have_http_status(:ok)

        admin1.reload
        expect(admin1.admin).to be true # Sigue siendo admin
      end

      it 'no puede acceder a usuarios de otro tenant' do
        patch "/api/v1/users/#{admin2.id}",
              params: { user: { active: false } },
              headers: auth_headers_for(admin1)

        # Debería fallar porque el usuario no existe en su tenant
        expect(response).to have_http_status(:not_found)

        admin2.reload
        expect(admin2.active).to be true # No ha cambiado
      end
    end
  end

  describe "Eliminación de usuarios (DELETE /api/v1/users/:id)" do
    context 'cuando el usuario es admin' do
      it 'puede eliminar un usuario de su tenant' do
        expect {
          delete "/api/v1/users/#{user1.id}",
                 headers: auth_headers_for(admin1)
        }.to change(User, :count).by(-1)

        expect(response).to have_http_status(:no_content)
        expect(User.find_by(id: user1.id)).to be_nil
      end

      it 'no puede eliminarse a sí mismo' do
        expect {
          delete "/api/v1/users/#{admin1.id}",
                 headers: auth_headers_for(admin1)
        }.not_to change(User, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'cuando el usuario no es admin' do
      it 'no puede eliminar a otros usuarios' do
        expect {
          delete "/api/v1/users/#{admin1.id}",
                 headers: auth_headers_for(user1)
        }.not_to change(User, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "Aislamiento entre tenants" do
    it 'un admin no puede ver usuarios de otro tenant' do
      # El admin de account1 no debería poder ver al admin de account2
      get "/api/v1/users", headers: auth_headers_for(admin1)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      user_ids = json.map { |u| u["id"] }

      expect(user_ids).not_to include(admin2.id)
    end

    it 'un usuario no puede acceder a recursos de otro tenant' do
      # Intentar acceder a un usuario de otro tenant debería fallar
      get "/api/v1/users/#{admin2.id}", headers: auth_headers_for(admin1)

      expect(response).to have_http_status(:not_found)
    end
  end
end
