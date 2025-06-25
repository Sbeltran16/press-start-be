class FollowsController < ApplicationController
  before_action :authenticate_user!

  def create
    user = User.find(params[:followed_id])
    follow = current_user.active_follows.build(followed: user)
    if follow.save
      render json: { status: 200, message: "Followed #{user.username}" }
    else
      render json: { status: 422, errors: follow.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    user = User.find(params[:id])
    current_user.following.delete(user)
    render json: { status: 200, message: "Unfollowed #{user.username}" }
  end

  def status
    followed = User.find(params[:id])
    is_following = current_user.following.exists?(followed.id)
    render json: { is_following: is_following }
  end

  def followers
    user = User.find(params[:id])
    followers = user.followers.where.not(id: user.id)

    render json: {
      data: followers.map { |follower| UserSerializer.new(follower).serializable_hash[:data][:attributes] }
    }
  end

  def following
    user = User.find(params[:id])
    following = user.following.where.not(id: user.id)

    render json: {
      data: following.map { |followed| UserSerializer.new(followed).serializable_hash[:data][:attributes] }
    }
  end
end
