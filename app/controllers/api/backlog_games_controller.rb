class Api::BacklogGamesController < ApplicationController
  before_action :authenticate_user!, only: [:create, :destroy, :index]

  def index
    if params[:username]
      user = User.find_by(username: params[:username])
      return render json: { error: "User not found" }, status: :not_found unless user
      backlog_ids = user.backlog_games.pluck(:igdb_game_id)
    else
      backlog_ids = current_user.backlog_games.pluck(:igdb_game_id)
    end

    render json: backlog_ids
  end

  def create
    igdb_game_id = params[:igdb_game_id]
    return render json: { error: "Missing igdb_game_id" }, status: :bad_request if igdb_game_id.blank?

    backlog_game = current_user.backlog_games.find_or_create_by(igdb_game_id: igdb_game_id)
    
    if backlog_game.persisted?
      render json: { success: true, id: backlog_game.id }, status: :created
    else
      render json: { errors: backlog_game.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    # Accept igdb_game_id from params (query string) or request body
    igdb_game_id = params[:igdb_game_id] || JSON.parse(request.body.read)["igdb_game_id"] rescue nil
    return render json: { error: "Missing igdb_game_id" }, status: :bad_request if igdb_game_id.blank?

    backlog_game = current_user.backlog_games.find_by(igdb_game_id: igdb_game_id)
    
    if backlog_game
      backlog_game.destroy
      render json: { success: true }, status: :ok
    else
      render json: { error: "Game not found in backlog" }, status: :not_found
    end
  end
end

