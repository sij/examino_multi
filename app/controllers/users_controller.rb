class UsersController < ApplicationController
  load_and_authorize_resource

  def index
    @users = User.all
  end

  def show
  end

  def new
    @user = User.new
  end

  def edit
    @user = User.find(params[:id])
  end

  def create
    @user = User.new(user_params)
    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: "User was successfully created." }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @user = User.find(params[:id])
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: "User was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy!
    respond_to do |format|
      format.html { redirect_to users_path, notice: "User was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def edit_password
    @user = User.find(params[:id])
  end

  def update_password
    @user = User.find(params[:id])
    respond_to do |format|
      if params[:user][:password].present? && params[:user][:password] == params[:user][:password_confirmation]
        if @user.update(password: params[:user][:password], password_confirmation: params[:user][:password_confirmation])
          format.html { redirect_to @user, notice: "Password updated successfully." }
          format.json { render :show, status: :ok, location: @user }
        else
          format.html { render :edit_password, status: :unprocessable_entity }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      else
        flash.now[:alert] = "New password and confirmation do not match."
        format.html { render :edit_password, status: :unprocessable_entity }
        format.json { render json: { error: "Password confirmation does not match" }, status: :unprocessable_entity }
      end
    end
  end

  def edit_my_password
    @user = current_user
  end

  def update_my_password
    @user = current_user
    unless @user.authenticate(params[:user][:current_password])
      flash.now[:alert] = "La password attuale non è corretta."
      render :edit_my_password, status: :unprocessable_entity
      return
    end

    if params[:user][:password].present? && params[:user][:password] == params[:user][:password_confirmation]
      if @user.update(password: params[:user][:password], password_confirmation: params[:user][:password_confirmation])
        redirect_to root_path, notice: "Password aggiornata con successo."
      else
        flash.now[:alert] = @user.errors.full_messages.join(", ")
        render :edit_my_password, status: :unprocessable_entity
      end
    else
      flash.now[:alert] = "Nuova password e conferma non coincidono."
      render :edit_my_password, status: :unprocessable_entity
    end
  end

  private

    def user_params
      params.require(:user).permit(:name, :email_address, :password, :password_confirmation, :info, :owner_id, :role_id, :enabled, :bet_point_id)
    end
end
