module JwtHelpers
  def auth_headers_for(user)
    token = generate_jwt_token_for(user)
    { 'Authorization': "Bearer #{token}" }
  end

  def generate_jwt_token_for(user)
    JWT.encode(
      {
        sub: user.id,
        jti: user.jti,
        scp: 'user',
        iat: Time.now.to_i,
        exp: 2.hours.from_now.to_i
      },
      ENV.fetch("DEVISE_JWT_SECRET_KEY", "test_secret_key_for_jwt"),
      'HS256'
    )
  end
end

RSpec.configure do |config|
  config.include JwtHelpers, type: :request
end
