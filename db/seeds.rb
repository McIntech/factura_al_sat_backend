# db/seeds.rb
if User.find_by(email: 'admin@cardiologiadelnorte.com')
  puts 'El usuario administrador ya existe.'
else
  User.create!(
    email: 'admin@cardiologiadelnorte.com',
    password: 'cArdioNort!',
    password_confirmation: 'cArdioNort!',
    first_name: 'Admin',
    last_name: 'Principal'
  )
  puts 'Usuario administrador creado exitosamente.'
end

# db/seeds.rb
if User.find_by(email: 'test+1760645754197@example.com')
  puts 'El usuario prueba ya existe.'
else
  User.create!(
    email: 'test+1760645754197@example.com',
    password: 'Test#12345',
    password_confirmation: 'Test#12345',
    first_name: 'Test',
    last_name: 'User'
  )
  puts 'Usuario de prueba creado exitosamente.'
end
