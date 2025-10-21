# Puma config: dev/prod ready, Docker/App Runner friendly

# ── Concurrency ──────────────────────────────────────────────────────────────
max_threads = Integer(ENV.fetch('RAILS_MAX_THREADS', '5'))
min_threads = Integer(ENV.fetch('RAILS_MIN_THREADS', max_threads.to_s))
threads min_threads, max_threads

workers_count = Integer(ENV.fetch('WEB_CONCURRENCY', '0')) # 0 = single mode (dev)
workers workers_count
preload_app! if workers_count > 0

# ── Environment & Port ───────────────────────────────────────────────────────
env = ENV.fetch('RAILS_ENV', 'development')
environment env

# Usa PORT si está definida (App Runner/Plataformas PaaS la inyectan), sino 3000
port ENV.fetch('PORT', '3000') # ⚠️ No agregues también 'bind' para evitar EADDRINUSE

# Identificadores (útil en observabilidad)
tag ENV.fetch('PUMA_TAG', 'factura-api')

# ── PIDs & State (útil para systemd/k8s si alguna vez los usas) ─────────────
pidfile ENV.fetch('PIDFILE', 'tmp/pids/server.pid')
state_path ENV.fetch('PUMA_STATE_PATH', 'tmp/puma.state')

# ── Logging ─────────────────────────────────────────────────────────────────
# En contenedores, preferimos STDOUT/STDERR
stdout_redirect '/dev/stdout', '/dev/stderr', true if ENV['PUMA_STDOUT_REDIRECT'] == '1'

# Reduce verbosidad si lo deseas (false = no silenciar)
quiet ENV.fetch('PUMA_QUIET', 'false') == 'true'

# ── Graceful shutdown / timeouts ─────────────────────────────────────────────
# En dev tolerante, en prod más estricto
worker_timeout Integer(ENV.fetch('PUMA_WORKER_TIMEOUT', env == 'development' ? '3600' : '60'))

# ── Plugins y recarga ────────────────────────────────────────────────────────
plugin :tmp_restart # `rails restart` reinicia Puma en dev

# ── Hooks para DB (ActiveRecord) ─────────────────────────────────────────────
if workers_count > 0
  before_fork do
    # Desconecta conexiones antes del fork
    ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
  end

  on_worker_boot do
    # Reconecta después del fork
    ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
  end
end

# ── Notas ───────────────────────────────────────────────────────────────────
# * No uses a la vez `port` y `bind` al mismo puerto (evita EADDRINUSE).
# * Controla concurrencia vía ENV:
#     RAILS_MAX_THREADS, RAILS_MIN_THREADS, WEB_CONCURRENCY
# * En Docker/compose agrega: RAILS_LOG_TO_STDOUT=1 para ver logs con `docker logs`.
