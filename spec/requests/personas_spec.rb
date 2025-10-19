require 'rails_helper'

RSpec.describe "Api::Personas", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }
  let(:persona_params) do
    {
      persona: {
        razon_social: "Empresa Test SA de CV",
        regimen_capital: "SOCIEDAD ANÓNIMA",
        email: "empresa@test.com",
        tipo_persona: "Persona Moral",
        rfc: "TEST123456ABC",
        regimen_fiscal: "601",
        uso_cfdi: "G01",
        codigo_postal: "12345",
        contrasena_sellos: "password123",
        curp: "ABCD123456HJCMRT07"
      }
    }
  end

  describe "GET /api/personas" do
    before do
      create_list(:persona, 3, user: user)
    end

    it "returns all personas for the current user" do
      get "/api/personas", headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(3)
    end
  end

  describe "GET /api/personas/:id" do
    let(:persona) { create(:persona, user: user) }

    it "returns the specified persona" do
      get "/api/personas/#{persona.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["id"]).to eq(persona.id)
    end

    it "returns not found for invalid persona id" do
      get "/api/personas/999", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/personas" do
    it "creates a new persona" do
      expect {
        post "/api/personas", params: persona_params, headers: headers
      }.to change(Persona, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "returns validation errors for invalid data" do
      post "/api/personas", params: { persona: { razon_social: "" } }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to have_key("errors")
    end
  end

  describe "PUT /api/personas/:id" do
    let(:persona) { create(:persona, user: user) }

    it "updates the specified persona" do
      put "/api/personas/#{persona.id}",
          params: { persona: { razon_social: "Updated Name" } },
          headers: headers

      expect(response).to have_http_status(:ok)
      expect(persona.reload.razon_social).to eq("Updated Name")
    end
  end

  describe "DELETE /api/personas/:id" do
    let!(:persona) { create(:persona, user: user) }

    it "deletes the specified persona" do
      expect {
        delete "/api/personas/#{persona.id}", headers: headers
      }.to change(Persona, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
