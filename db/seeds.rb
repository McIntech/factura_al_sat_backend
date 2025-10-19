# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Crear usuario administrador si no existe
unless User.find_by(email: 'admin@cardiologiadelnorte.com')
  User.create!(
    email: 'admin@cardiologiadelnorte.com',
    password: 'cArdioNort!',
    password_confirmation: 'cArdioNort!'
  )
  puts "Usuario administrador creado exitosamente."
else
  puts "El usuario administrador ya existe."
end
