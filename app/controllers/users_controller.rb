class UsersController < ApplicationController
  before_action :authenticate_user!, only: [:me, :update_picture]
  skip_before_action :authenticate_user!, only: [:show, :search]
  skip_before_action :check_email_confirmation, only: [:show, :search]

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

  def search
    query = params[:q] || params[:query]
    return render json: { data: [] }, status: :ok if query.blank? || query.length < 2

    # Search users by username (case-insensitive, partial match)
    users = User.where("LOWER(username) LIKE ?", "%#{query.downcase}%")
                .limit(10)
                .order(:username)

    render json: {
      data: users.map { |user| UserSerializer.new(user).serializable_hash[:data][:attributes] }
    }
  end

  def update_picture
    Rails.logger.info "Params: #{params.inspect}"
    if current_user.update(params.require(:user).permit(:profile_picture))
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
