FactoryBot.define do
  factory :persona do
    razon_social { "Empresa Test SA de CV" }
    regimen_capital { "SOCIEDAD ANÓNIMA" }
    sequence(:email) { |n| "empresa#{n}@test.com" }
    tipo_persona { [ "Persona Física", "Persona Moral" ].sample }
    sequence(:rfc) { |n| "TEST#{n}ABC123" }
    regimen_fiscal { "601" }
    uso_cfdi { "G01" }
    codigo_postal { "12345" }
    contrasena_sellos { "password123" }
    curp { "ABCD123456HJCMRT07" }
    association :user
  end
end
