# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # Utente guest (non autenticato)

    if user.admin?
      can :manage, :all # L’admin può fare tutto su tutte le risorse
    else
     can :edit_my_password, User, id: user.id
     can :update_my_password, User, id: user.id

     # can :read, Post # Un utente normale può leggere i post
     # can :create, Post # Può creare nuovi post
     # can :update, Post, user_id: user.id # Può modificare solo i propri post
     # can :destroy, Post, user_id: user.id # Può cancellare solo i propri post
    end
  end
end