FactoryBot.define do
  factory :user do
    # Para hacer que el tenant sea opcional en los tests
    transient do
      skip_tenant { true }
    end

    after(:build) do |user, evaluator|
      if evaluator.skip_tenant && user.account.nil?
        # Solo crear un account si no se proporcionó uno y skip_tenant está activo
        user.account = build(:account) unless user.account
      end
    end

    email { Faker::Internet.unique.email }
    password { "password123" }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    admin { false }
    active { true }
    confirmed_at { Time.current }
    jti { SecureRandom.uuid }

    trait :admin do
      admin { true }
    end

    trait :inactive do
      active { false }
    end

    trait :unconfirmed do
      confirmed_at { nil }
    end
  end
end
