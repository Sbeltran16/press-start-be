class UsersController < ApplicationController
  before_action :authenticate_user!, only: [:me, :update_picture, :update, :check_username]
  skip_before_action :authenticate_user!, only: [:show, :search]

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

  def update
    if current_user.update(user_params)
      render json: { 
        status: 200, 
        data: UserSerializer.new(current_user).serializable_hash[:data][:attributes] 
      }
    else
      render json: { 
        status: 422, 
        errors: current_user.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end

  def check_username
    username = params[:username]&.strip
    return render json: { available: false, error: "Username is required" }, status: :bad_request if username.blank?

    # Validate username length
    if username.length < 3
      return render json: { 
        available: false, 
        message: "Username must be at least 3 characters" 
      }
    end

    if username.length > 30
      return render json: { 
        available: false, 
        message: "Username must be 30 characters or less" 
      }
    end

    # Check if username is taken (excluding current user)
    existing_user = User.where("LOWER(username) = ?", username.downcase)
                        .where.not(id: current_user.id)
                        .first

    render json: { 
      available: existing_user.nil?,
      message: existing_user ? "Username is already taken" : "Username is available"
    }
  end

  private

  def user_params
    params.require(:user).permit(:username, :email, :password, :bio, :location, :profile_picture, :profile_banner)
  end
end
