class CreatePersonas < ActiveRecord::Migration[8.0]
  def change
    create_table :personas do |t|
      t.string :razon_social
      t.string :regimen_capital
      t.string :email
      t.string :tipo_persona
      t.string :rfc
      t.string :regimen_fiscal
      t.string :uso_cfdi
      t.string :codigo_postal
      t.string :contrasena_sellos
      t.string :curp
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
