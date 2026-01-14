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

  def popular
    # Get all public lists, sorted by likes_count and updated_at
    # Use a left join to count likes and order by that count
    lists = GameList.includes(:user, :list_likes)
                    .left_joins(:list_likes)
                    .group('game_lists.id')
                    .order('COUNT(list_likes.id) DESC, game_lists.updated_at DESC')
                    .limit(10)

    render json: {
      data: lists.map { |list| GameListSerializer.new(list, { params: { current_user: current_user } }).serializable_hash[:data][:attributes] }
    }
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

