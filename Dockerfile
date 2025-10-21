FROM ruby:3.2

# Establece el entorno de Rails a producción
ENV RAILS_ENV=production

# Instala dependencias del sistema
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs

# Crea y usa el directorio de la app
WORKDIR /rails_image

# Copia Gemfile y Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Instala gems
RUN bundle install --without development test

# Copia el resto de la aplicación
COPY . .

# Expone el puerto por defecto de Rails
EXPOSE 3000

# Configura el entrypoint
COPY bin/entrypoint.sh /rails_image/entrypoint.sh
RUN chmod +x /rails_image/entrypoint.sh
ENTRYPOINT ["/rails_image/entrypoint.sh"]
# Comando para iniciar el servidor
CMD ["rails", "server", "-b", "0.0.0.0"]
