FactoryBot.define do
  factory :account do
    name { "Empresa #{SecureRandom.hex(4)}" }
  end
end
