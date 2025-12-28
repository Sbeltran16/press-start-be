class Api::BacklogGamesController < ApplicationController
  before_action :authenticate_user!, only: [:create, :destroy]
  before_action :check_backlog_table_exists

  def index
    if params[:username]
      user = User.find_by(username: params[:username])
      return render json: { error: "User not found"}, status: :not_found unless user

      if user.respond_to?(:backlog_games)
        render json: user.backlog_games.pluck(:igdb_game_id)
      else
        render json: []
      end
    else
      if current_user.respond_to?(:backlog_games)
        render json: current_user.backlog_games.pluck(:igdb_game_id)
      else
        render json: []
      end
    end
  end

  def create
    unless current_user.respond_to?(:backlog_games)
      return render json: { error: "Backlog feature not available. Please run migrations." }, status: :service_unavailable
    end

    igdb_id = params[:igdb_game_id]
    
    unless igdb_id
      return render json: { error: "igdb_game_id is required" }, status: :unprocessable_entity
    end

    # Check if already in backlog
    existing = current_user.backlog_games.find_by(igdb_game_id: igdb_id)
    if existing
      return render json: { message: "Game already in backlog" }, status: :ok
    end

    backlog_game = current_user.backlog_games.create!(igdb_game_id: igdb_id)
    render json: { message: "Game added to backlog", id: backlog_game.id }, status: :created
  end

  def destroy
    unless current_user.respond_to?(:backlog_games)
      return render json: { error: "Backlog feature not available. Please run migrations." }, status: :service_unavailable
    end

    igdb_id = params[:id] # The route will be /api/backlog_games/:id where :id is the igdb_game_id
    
    backlog_game = current_user.backlog_games.find_by(igdb_game_id: igdb_id)
    
    if backlog_game
      backlog_game.destroy
      render json: { message: "Game removed from backlog" }, status: :ok
    else
      render json: { error: "Game not found in backlog" }, status: :not_found
    end
  end

  private

  def check_backlog_table_exists
    unless ActiveRecord::Base.connection.table_exists?('backlog_games')
      # Don't block the request, just log a warning
      Rails.logger.warn("backlog_games table does not exist. Please run migrations.")
    end
  end
end

