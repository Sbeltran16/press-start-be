class UsersController < ApplicationController
  before_action :authenticate_user!, only: [:me]

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
    user = User.find_by(username: params[:username])

    if user
      render json: {
        status: 200,
        data: UserSerializer.new(user).serializable_hash[:data][:attributes]
      }
    else
      render json: {status: 404, error: "User not found"}
    end
  end

  private

  def user_params
    params.require(:user).permit(:username, :email, :password, :bio, :profile_picture, :profile_banner)
  end
end
