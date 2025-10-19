# app/controllers/api/v1/users_controller.rb
class Api::V1::UsersController < ApplicationController
  include UserSerialization
  before_action :set_user, only: [ :show, :update, :destroy ]

  def index
    users = policy_scope(User)
    authorize users
    
    # Usar el mismo método serialize_user para consistencia
    users_data = users.map { |user| serialize_user(user) }
    
    render json: users_data
  end

  def create
    authorize User
    user = current_user.account.users.build(user_params)
    user.password ||= SecureRandom.base58(12)
    user.confirmed_at = Time.current # opcional: forzar confirmado (o envía email de confirmación)
    user.save!
    render json: { id: user.id }, status: :created
  end

  def update
    authorize @user
    # Admin no puede cambiar de account ni “quitarse” a sí mismo admin en este ejemplo
    @user.update!(user_params.except(:account_id))
    render json: { ok: true }
  end

  def destroy
    authorize @user
    @user.destroy!
    head :no_content
  end

  def show
    authorize @user
    
    # Usar el método serialize_user para mantener consistencia
    user_data = serialize_user(@user)
    
    # Añadir campos adicionales específicos del endpoint show
    user_data.merge!(@user.slice(:phone, :company_name, :state))
    
    render json: user_data
  end

  private

  def set_user
    if params[:id].to_i == current_user.id
      # Si el usuario está solicitando su propia información, simplemente use current_user
      @user = current_user
    elsif current_user.account
      # Si el usuario tiene una cuenta, busque a través de la relación de la cuenta
      @user = current_user.account.users.find(params[:id])
    elsif current_user.admin
      # Si el usuario es un admin pero no tiene cuenta, permita acceder a cualquier usuario
      @user = User.find(params[:id])
    else
      # Si no tiene cuenta ni es admin, solo puede ver su propia información
      raise ActiveRecord::RecordNotFound unless params[:id].to_i == current_user.id
      @user = current_user
    end
  end

  def user_params
    params.require(:user).permit(:email, :first_name, :last_name, :admin, :active, :password, :password_confirmation, :letterhead, :letterhead_filename, :state, :company_name, :phone)
  end
end
