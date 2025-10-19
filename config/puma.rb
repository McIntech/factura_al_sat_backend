# Puma prod sensible defaults
max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 5).to_i
min_threads_count = ENV.fetch("RAILS_MIN_THREADS", max_threads_count).to_i
threads min_threads_count, max_threads_count

port        ENV.fetch("PORT", 3000)
environment ENV.fetch("RAILS_ENV", "production")
workers     ENV.fetch("WEB_CONCURRENCY", 2).to_i
preload_app!

# Tiempos amables para App Runner
worker_timeout 60 if ENV["RAILS_ENV"] == "production"

# Log a STDOUT (CloudWatch recoge)
stdout_redirect nil, nil, true

# /up para health checks
lowlevel_error_handler do |ex, env|
  [ 500, { "Content-Type" => "text/plain" }, [ "Puma lowlevel error: #{ex.message}" ] ]
end
