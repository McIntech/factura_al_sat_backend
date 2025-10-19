namespace :admin do
  desc "Crear usuario administrador"
  task create_admin: :environment do
    User.create!(
      email: "admin@cardiologiadelnorte.com",
      password: "cArdioNort!",
      password_confirmation: "cArdioNort!"
    )
    puts "Usuario administrador creado correctamente."
  end
end
