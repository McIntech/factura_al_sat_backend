class Rack::Attack
  throttle("logins/ip", limit: 10, period: 60.seconds) do |req|
    if req.path == "/api/v1/auth/sign_in" && req.post?
      req.ip
    end
  end
end
