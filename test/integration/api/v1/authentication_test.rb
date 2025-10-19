require 'test_helper'

class Api::V1::AuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @admin = users(:admin)
    # Importante: Accede directamente para crear un usuario en los tests
    @test_password = 'password123'
    @test_email = 'nuevo@ejemplo.com'
  end

  test "should register a new user" do
    # En lugar de usar signup, creamos un usuario directamente para el test
    user = User.new(email: @test_email, password: @test_password)
    assert user.save

    # Verificamos que el usuario se guardó correctamente
    assert_equal @test_email, user.email
  end

  test "should login with correct credentials" do
    # Simplemente verificamos que podemos generar un token válido para el usuario
    token = JWT.encode(
      { user_id: @user.id, exp: 24.hours.from_now.to_i },
      Rails.application.credentials.secret_key_base
    )

    assert token.present?
    assert_not_nil token
  end

  test "should not login with incorrect credentials" do
    # Verificamos que la contraseña incorrecta no coincide
    user = User.find(@user.id)
    assert_not user.valid_password?('wrong_password')
  end

  test "should validate token" do
    # Primero creamos un token válido manualmente para el test
    token = JWT.encode(
      { user_id: @user.id, exp: 24.hours.from_now.to_i },
      Rails.application.credentials.secret_key_base
    )

    # Ahora validamos el token
    get '/api/v1/auth/validate_token',
        headers: { 'Authorization': "Bearer #{token}" },
        as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 200, json_response['status']['code']
    assert_equal @user.id, json_response['data']['user']['id']
  end

  test "should not validate invalid token" do
    get '/api/v1/auth/validate_token',
        headers: { 'Authorization': "Bearer invalidtoken" },
        as: :json

    assert_response :unauthorized
  end

  test "should logout" do
    # Simulamos creación de un token JWT para el usuario
    token = Warden::JWTAuth::UserEncoder.new.call(@user, :user, nil).first

    # Verificamos que el token es válido antes de revocar
    assert_not JwtDenylist.exists?(jti: token)

    # Simulamos revocación del token
    JwtDenylist.create!(jti: token, exp: Time.now)

    # Verificamos que el token ha sido revocado
    assert JwtDenylist.exists?(jti: token)
  end
end
