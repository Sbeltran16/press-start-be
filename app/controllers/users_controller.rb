class UsersController < ApplicationController
  before_action :authenticate_user!, only: [:me, :update]

  def me
    if current_user
      render json: {
        status: 200,
        data: UserSerializer.new(current_user).serializable_hash[:data][:attributes]
      }
    else
      render json: { status: 401, error: "Unauthorized" }
    end
  end

  def show
    user = User.where("LOWER(username) = ?", params[:username].to_s.downcase).first

    if user
      render json: {
        status: 200,
        data: UserSerializer.new(user).serializable_hash[:data][:attributes]
      }
    else
      render json: { status: 404, error: "User not found" }
    end
  end

  def update
    if current_user.update(user_params)
      render json: { status: 200, data: UserSerializer.new(current_user).serializable_hash[:data][:attributes] }
    else
      render json: { status: 422, errors: current_user.errors.full_messages }
    end
  end

  private

  def user_params
    params.require(:user).permit(:username, :email, :password, :bio, :profile_picture, :profile_banner)
  end
end
