class User < ApplicationRecord
  # En desarrollo y producción, puede haber usuarios sin tenant si son administradores raíz
  belongs_to :account, optional: true
  has_many :personas, dependent: :destroy

  # ActiveStorage attachment for letterhead template
  has_one_attached :letterhead

  # --- 📋 Validaciones ---
  validates :first_name, :last_name, presence: false

  # Unicidad de email global, ignorando tenant (evita duplicados entre cuentas)
  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }

  # --- 🔐 Devise configuration ---
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :jwt_authenticatable,
         jwt_revocation_strategy: self

  # --- 🔑 JWT management ---
  before_create :set_jti

  def set_jti
    self.jti = SecureRandom.uuid
  end

  def self.jwt_revoked?(payload, user)
    token_jti = payload['jti']
    user_jti = user.jti
    Rails.logger.info "JWT Verification - Token JTI: #{token_jti}, User JTI: #{user_jti}"

    is_revoked = token_jti != user_jti
    Rails.logger.info is_revoked ? "JWT REVOKED: Token no válido para el usuario #{user.id}" : "JWT válido para el usuario #{user.id}"

    is_revoked
  end

  def self.revoke_jwt(_payload, user)
    user.update!(jti: SecureRandom.uuid)
  end

  # --- 🧩 Helpers ---
  def full_name
    "#{first_name} #{last_name}".strip
  end
end
