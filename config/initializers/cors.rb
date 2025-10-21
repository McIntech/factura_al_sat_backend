Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Desarrollo local: Vite/React/Vue en puertos 5173, 5174, 5175
    origins 'http://localhost:5173', 'http://localhost:5174', 'http://localhost:5175'

    resource '*',
             headers: :any,
             methods: %i[get post put patch delete options head],
             credentials: true,
             expose: %w[Content-Disposition Content-Type Access-Control-Allow-Origin]
  end

  allow do
    # Producción: CloudFront y dominios propios
    origins 'https://dw70y6k7lwehw.cloudfront.net',
            'https://facturaalsat.com',
            'https://www.facturaalsat.com'

    resource '*',
             headers: :any,
             methods: %i[get post put patch delete options head],
             credentials: true,
             expose: %w[Content-Disposition Content-Type Access-Control-Allow-Origin]
  end
end
