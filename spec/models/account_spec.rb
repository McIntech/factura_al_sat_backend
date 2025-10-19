require 'rails_helper'

RSpec.describe Account, type: :model do
  describe "associations" do
    it { should have_many(:users).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
  end

  describe "creación de cuenta" do
    it "crea una cuenta válida con nombre" do
      account = Account.new(name: "Empresa Test")
      expect(account).to be_valid
    end

    it "no crea una cuenta sin nombre" do
      account = Account.new(name: nil)
      expect(account).not_to be_valid
      expect(account.errors[:name]).to include("can't be blank")
    end
  end

  describe "multi-tenancy" do
    let!(:account1) { create(:account) }
    let!(:account2) { create(:account) }

    it "aísla los usuarios entre cuentas" do
      user1 = nil
      user2 = nil

      with_tenant(account1) do
        user1 = create(:user)
        expect(account1.users).to include(user1)
      end

      with_tenant(account2) do
        user2 = create(:user)
        expect(account2.users).to include(user2)
      end

      # Verificar aislamiento
      with_tenant(account1) do
        expect(account1.users).not_to include(user2)
      end
      with_tenant(account2) do
        expect(account2.users).not_to include(user1)
      end
    end
  end
end
