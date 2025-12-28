class Api::GamesController < ApplicationController
  before_action :authenticate_user!, only: [:user_game_status]
  require 'net/http'
  require 'json'

  CLIENT_ID = ENV['TWITCH_CLIENT_ID']
  CLIENT_SECRET = ENV['TWITCH_CLIENT_SECRET']

  def user_game_status
    if current_user
      liked = current_user.game_likes.exists?(igdb_game_id: params[:igdb_game_id])
      played = current_user.game_plays.exists?(igdb_game_id: params[:igdb_game_id])
    else
      liked = false
      played = false
    end
    render json: { liked: liked, played: played }
  end
 # Game Index
  def index
    if params[:name]
      @games = Game.where("name ILIKE ?", "%#{params[:name]}%")
    else
      @games = Game.all
    end

    render json: @games
  end

  def popular
    top_game_ids = GameScoreService.top_game_ids(limit: 12)
    
    # If no games have interactions yet, fallback to top liked games
    if top_game_ids.empty?
      top_game_ids = GameLike.group(:igdb_game_id).order('count_id DESC').count(:id).keys.take(12)
    end
    
    # If still empty, return empty array instead of making invalid API call
    if top_game_ids.empty?
      render json: []
      return
    end
    
    fields = "id, name, cover.image_id, artworks.image_id, rating, summary"
    where_clause = "where id = (#{top_game_ids.join(',')});"
    games = IgdbService.fetch_games(query: "", fields: fields, where_clause: where_clause, limit: 6)

    if games && games.any?
      scores = GameScoreService.scores_for(top_game_ids)
      games_with_scores = games.map do |game|
        game["score"] = scores[game["id"]] || 0
        game
      end
      render json: games_with_scores
    else
      # Fallback: return empty array instead of error
      render json: []
    end
  end

  def top
    top_game_ids = GameLike.group(:igdb_game_id).order('count_id DESC').count(:id).keys.take(12)

    # If no games have likes yet, return empty array
    if top_game_ids.empty?
      render json: []
      return
    end

    fields = "name, cover.image_id, artworks.image_id, updated_at, summary, release_dates, rating, genres.name"
    where_clause = "where id = (#{top_game_ids.join(',')});"

    games = IgdbService.fetch_games(
      query: "",
      fields: fields,
      where_clause: where_clause,
      limit: 12
    )

    if games && games.any?
      render json: games
    else
      # Return empty array instead of error
      render json: []
    end
  end

  def show_by_name
    name = params[:name]
    return render json: { error: 'Missing name parameter' }, status: :bad_request if name.blank?

    decoded_name = CGI.unescape(name)

    fields = %w[
      name cover.image_id summary rating aggregated_rating first_release_date
      storyline genres.name platforms.name release_dates.human artworks.image_id
      screenshots.image_id videos.video_id videos.name involved_companies.company.name
      similar_games.name similar_games.cover.image_id similar_games.first_release_date
      age_ratings.rating age_ratings.category
    ].join(", ")

    games = IgdbService.fetch_games(
      query: "search \"#{decoded_name}\";",
      fields: fields,
      where_clause: "where cover != null;",
      limit: 40
    )

    if games&.any?
      render json: games.first
    else
      render json: { error: "Game not found" }, status: :not_found
    end
  end

  def search_by_name
    name = params[:name]
    return render json: { error: 'Missing name parameter' }, status: :bad_request if name.blank?

    decoded_name = CGI.unescape(name).gsub('"', '\"').gsub('\\', '')

    games = IgdbService.fetch_games(
      query: "search \"#{decoded_name}\";",
      fields: "name, cover.image_id, summary, rating, first_release_date",
      where_clause: "",
      limit: 50
    )

    if games
      render json: games
    else
      render json: { error: "Failed to fetch games" }, status: :bad_request
    end
  end


  def show_by_id
    igdb_game_id = params[:id]

    fields = %w[
      name cover.image_id summary aggregated_rating first_release_date
      storyline genres.name game_engines.name platforms.name release_dates.human
      artworks.image_id screenshots.image_id language_supports.language.name
      videos.video_id videos.name involved_companies.company.name
      similar_games.name similar_games.cover.image_id similar_games.first_release_date
      age_ratings.rating age_ratings.category
    ].join(", ")

    games = IgdbService.fetch_games(
      query: "",
      fields: fields,
      where_clause: "where id = #{igdb_game_id};",
      limit: 1
    )
    if games&.first
      game = games.first
      steam_url = IgdbService.fetch_steam_url(igdb_game_id)
      game["steam_url"] = steam_url if steam_url
      render json: game
    else
      render json: { error: "Game not found" }, status: :not_found
    end
  end
end