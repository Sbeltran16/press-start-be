class Api::GameListsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :popular]
  before_action :set_game_list, only: [:show, :update, :destroy]

  def index
    if params[:username]
      user = User.find_by(username: params[:username])
      return render json: { error: "User not found" }, status: :not_found unless user
      lists = user.game_lists.order(updated_at: :desc)
    else
      return render json: { error: "Unauthorized" }, status: :unauthorized unless current_user
      lists = current_user.game_lists.order(updated_at: :desc)
    end

    render json: {
      data: lists.map { |list| GameListSerializer.new(list, { params: { current_user: current_user } }).serializable_hash[:data][:attributes] }
    }
  end

  def from_friends
    return render json: { error: "Unauthorized" }, status: :unauthorized unless current_user
    
    following_ids = current_user.following.pluck(:id)
    # Include the current user's own lists as well so the feed is never empty
    # when the user has created lists (matches "yourself and friends" concept).
    user_ids = ([current_user.id] + following_ids).uniq
    
    if user_ids.empty?
      render json: { data: [] }
      return
    end
    
    limit = params[:limit] ? params[:limit].to_i : 6
    
    lists = GameList.includes(:user, :list_likes)
                    .where(user_id: user_ids)
                    .order(created_at: :desc)
                    .limit(limit)
    
    render json: {
      data: lists.map { |list| GameListSerializer.new(list, { params: { current_user: current_user } }).serializable_hash[:data][:attributes] }
    }
  end

  def popular
    # Get all public lists from ALL users, sorted by likes_count and updated_at
    # This endpoint is public and shows lists from everyone, not just the current user
    limit = params[:limit] ? params[:limit].to_i : 10
    time_period = params[:period] || 'all_time'
    
    # Calculate date threshold based on time period
    date_threshold = case time_period
    when 'this_week'
      1.week.ago
    when 'this_month'
      1.month.ago
    when 'this_year'
      1.year.ago
    when 'all_time'
      nil
    else
      nil
    end
    
    begin
      base_query = GameList.includes(:user, :list_likes)
      
      if date_threshold
        base_query = base_query.where('game_lists.updated_at >= ?', date_threshold)
      end
      
      # Get lists and sort by popularity
      recent_lists = base_query
                     .order(updated_at: :desc)
                     .limit(100) # Get more to ensure diversity across users
      
      # Sort by likes count in memory (much faster for smaller dataset)
      sorted_lists = recent_lists.sort_by do |list|
        [-list.likes_count, -list.updated_at.to_i]
      end.take(limit)

      render json: {
        data: sorted_lists.map { |list| GameListSerializer.new(list, { params: { current_user: current_user } }).serializable_hash[:data][:attributes] }
      }
    rescue => e
      Rails.logger.error "Error fetching popular lists: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      # Fallback: just get recent lists from all users without likes sorting
      lists = GameList.includes(:user, :list_likes)
                      .order(updated_at: :desc)
                      .limit(limit)
      
      render json: {
        data: lists.map { |list| GameListSerializer.new(list, { params: { current_user: current_user } }).serializable_hash[:data][:attributes] }
      }
    end
  end

  def show
    render json: {
      data: GameListSerializer.new(@game_list, { params: { current_user: current_user } }).serializable_hash[:data][:attributes]
    }
  end

  def create
    game_list = current_user.game_lists.build(game_list_params)

    if game_list.save
      render json: {
        data: GameListSerializer.new(game_list, { params: { current_user: current_user } }).serializable_hash[:data][:attributes]
      }, status: :created
    else
      render json: { errors: game_list.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @game_list.update(game_list_params)
      render json: {
        data: GameListSerializer.new(@game_list, { params: { current_user: current_user } }).serializable_hash[:data][:attributes]
      }
    else
      render json: { errors: @game_list.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @game_list.destroy
    render json: { success: true }, status: :ok
  end

  private

  def set_game_list
    @game_list = GameList.find(params[:id])
    # Only allow users to modify their own lists
    if action_name != 'show' && @game_list.user_id != current_user&.id
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  def game_list_params
    params.require(:game_list).permit(:name, :description)
  end
end

