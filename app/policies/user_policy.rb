# app/policies/user_policy.rb
class UserPolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def create?
    user.admin?
  end

  def update?
    user.admin? || record.id == user.id
  end

  def destroy?
    user.admin? && record.id != user.id
  end

  class Scope < Scope
    def resolve
      scope.where(account_id: user.account_id)
    end
  end
end
