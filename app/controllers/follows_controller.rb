class FollowsController < ApplicationController
  before_action :authenticate_user!

  def create
    user = User.find(params[:followed_id])
    current_user.following << user unless current_user.following.include?(user)
    render json: { status: 200, message: "Followed #{user.username}" }
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
end
