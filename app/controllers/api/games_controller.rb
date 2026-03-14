class Api::GamesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :popular, :top, :show_by_name, :show_by_id, :stats, :by_genre, :by_year, :by_console, :by_decade, :most_popular_igdb, :most_anticipated_igdb, :alternative_covers]
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

  def stats
    igdb_game_id = params[:igdb_game_id] || params[:id]
    return render json: { plays: 0, likes: 0 }, status: :ok if igdb_game_id.blank?

    # Both game_likes and game_plays store igdb_game_id as string
    # Convert to string to ensure consistent querying
    game_id = igdb_game_id.to_s
    
    # Use count for accurate numbers
    plays_count = GamePlay.where(igdb_game_id: game_id).count
    likes_count = GameLike.where(igdb_game_id: game_id).count

    render json: { plays: plays_count, likes: likes_count }, status: :ok
  end
  # Game Index: returns cached games only (optional name filter)
  def index
    if params[:name].present?
      games = Game.where("name ILIKE ?", "%#{params[:name]}%").limit(100)
      render json: games.map(&:to_igdb_response)
    else
      render json: []
    end
  end

  def popular
    time_period = params[:period] || 'all_time'
    limit = params[:limit] ? params[:limit].to_i : 12

    top_game_ids = GameScoreService.top_game_ids(limit: limit, time_period: time_period)
    if top_game_ids.empty?
      likes_query = GameLike
      if time_period != 'all_time'
        date_threshold = case time_period
        when 'this_week' then 1.week.ago
        when 'this_month' then 1.month.ago
        when 'this_year' then 1.year.ago
        end
        likes_query = likes_query.where("created_at >= ?", date_threshold) if date_threshold
      end
      top_game_ids = likes_query.group(:igdb_game_id).order('count_id DESC').count(:id).keys.take(limit)
    end

    if top_game_ids.empty?
      render json: []
      return
    end

    ids = top_game_ids.map(&:to_i)
    fields = "id, name, cover.image_id, artworks.image_id, screenshots.image_id, rating, summary"
    games = GameCacheService.find_or_fetch_batch(ids) do |missing_ids|
      IgdbService.fetch_games(
        query: "",
        fields: fields,
        where_clause: "where id = (#{missing_ids.join(',')});",
        limit: missing_ids.size
      )
    end

    if games.any?
      scores = GameScoreService.scores_for(ids)
      games_with_scores = games.map do |game|
        game["score"] = scores[game["id"]] || 0
        game
      end
      render json: games_with_scores
    else
      render json: []
    end
  end

  def top
    Rails.logger.info("Top games endpoint called")

    unless ENV['TWITCH_CLIENT_ID'] && ENV['TWITCH_CLIENT_SECRET']
      Rails.logger.error("IGDB credentials not configured")
      render json: { error: "IGDB API not configured" }, status: :service_unavailable
      return
    end

    top_game_ids = GameLike.group(:igdb_game_id).order('count_id DESC').count(:id).keys.take(12)
    Rails.logger.info("Top game IDs from database: #{top_game_ids.length}")

    fields = "name, cover.image_id, artworks.image_id, screenshots.image_id, updated_at, summary, release_dates, rating, genres.name"

    if top_game_ids.empty?
      Rails.logger.info("No game likes found, fetching from IGDB")
      games = IgdbService.fetch_games(
        query: "",
        fields: fields,
        where_clause: "where rating >= 75 & cover != null & first_release_date > 946684800;",
        limit: 12
      )
      if games && games.any?
        GameCacheService.upsert_many_from_igdb(games)
        games = games.sort_by { |g| [-(g["rating"] || 0), -(g["first_release_date"] || 0)] }
        render json: games
        return
      end
      fallback_games = IgdbService.fetch_games(
        query: "",
        fields: fields,
        where_clause: "where cover != null & rating != null;",
        limit: 12
      )
      if fallback_games && fallback_games.any?
        GameCacheService.upsert_many_from_igdb(fallback_games)
        fallback_games = fallback_games.sort_by { |g| -(g["rating"] || 0) }
        render json: fallback_games
      else
        render json: []
      end
      return
    end

    ids = top_game_ids.map(&:to_i)
    games = GameCacheService.find_or_fetch_batch(ids) do |missing_ids|
      IgdbService.fetch_games(
        query: "",
        fields: fields,
        where_clause: "where id = (#{missing_ids.join(',')});",
        limit: missing_ids.size
      )
    end

    if games.any?
      render json: games
    else
      fallback_games = IgdbService.fetch_games(
        query: "",
        fields: fields,
        where_clause: "where rating >= 80 & cover != null;",
        limit: 12
      )
      if fallback_games && fallback_games.any?
        GameCacheService.upsert_many_from_igdb(fallback_games)
        render json: fallback_games.sort_by { |g| -(g["rating"] || 0) }
      else
        render json: []
      end
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

    game = GameCacheService.find_or_fetch_by_name(decoded_name) do
      IgdbService.fetch_games(
        query: "search \"#{decoded_name}\";",
        fields: fields,
        where_clause: "where cover != null;",
        limit: 40
      )
    end

    if game.present?
      render json: game
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
      fields: "id, name, cover.image_id, summary, rating, first_release_date",
      where_clause: "",
      limit: 50
    )

    if games && games.any?
      GameCacheService.upsert_many_from_igdb(games)
      render json: games
    elsif games
      render json: []
    else
      render json: { error: "Failed to fetch games" }, status: :bad_request
    end
  end


  def batch
    game_ids = params[:ids]
    return render json: { error: 'Missing ids parameter' }, status: :bad_request if game_ids.blank?

    ids = if game_ids.is_a?(Array)
            game_ids.map(&:to_i)
          else
            game_ids.to_s.split(',').map(&:to_i).reject(&:zero?)
          end
    ids = ids.uniq.take(50)
    return render json: {}, status: :ok if ids.empty?

    games_array = GameCacheService.find_or_fetch_batch(ids) do |missing_ids|
      IgdbService.fetch_games(
        query: "",
        fields: GameCacheService::FULL_GAME_FIELDS,
        where_clause: "where id = (#{missing_ids.join(',')});",
        limit: missing_ids.size
      )
    end

    games_hash = games_array.index_by { |g| g["id"] }
    render json: games_hash
  end

  def show_by_id
    igdb_game_id = params[:id]
    return render json: { error: "Game not found" }, status: :not_found if igdb_game_id.blank?

    game = GameCacheService.find_or_fetch_by_id(igdb_game_id) do
      IgdbService.fetch_games(
        query: "",
        fields: GameCacheService::FULL_GAME_FIELDS,
        where_clause: "where id = #{igdb_game_id.to_i};",
        limit: 1
      )
    end

    if game.present?
      # If cached game is thin (missing details/screenshots/videos), enrich from IGDB
      if GameCacheService.thin?(game)
        game = GameCacheService.enrich_game(igdb_game_id) || game
      end
      # Fill and persist steam_url and external_links (where to buy) when missing
      if game["steam_url"].blank? || game["external_links"].blank?
        steam_url = game["steam_url"].presence || IgdbService.fetch_steam_url(igdb_game_id)
        external_links = game["external_links"].presence || IgdbService.fetch_external_links_formatted(igdb_game_id)
        game["steam_url"] = steam_url if steam_url.present?
        game["external_links"] = external_links if external_links.present?
        GameCacheService.update_external_data(igdb_game_id, steam_url: steam_url, external_links: external_links)
      end
      render json: game
    else
      render json: { error: "Game not found" }, status: :not_found
    end
  end

  def alternative_covers
    igdb_game_id = params[:id]
    return render json: { error: 'Missing game ID' }, status: :bad_request if igdb_game_id.blank?

    covers = IgdbService.fetch_game_covers(igdb_game_id)
    render json: covers
  end

  def by_genre
    genre = params[:genre]
    return render json: { error: 'Missing genre parameter' }, status: :bad_request if genre.blank?

    # Map genre name to IGDB genre ID (common genres)
    # IGDB genre IDs: https://api-docs.igdb.com/#genre-ids
    genre_map = {
      'Action' => 4,
      'Adventure' => 31,
      'RPG' => 12,
      'Strategy' => 15,
      'Simulation' => 13,
      'Sports' => 14,
      'Racing' => 10,
      'Shooter' => 5,
      'Puzzle' => 9,
      'Indie' => 32
    }

    genre_id = genre_map[genre] || genre_map[genre.capitalize]
    return render json: [], status: :ok unless genre_id

    # Fetch games - no rating requirement to get maximum results
    # Games with multiple genres will be included if they have this genre in their genres array
    # The = operator in IGDB checks if the value is in the array, so games with multiple genres work
    # Include genres field to verify the query is working
    fields = "id, name, cover.image_id, first_release_date, rating, aggregated_rating, summary, genres"
    
    # Query: games that have this genre in their genres array (supports multiple genres)
    # In IGDB API v4, use the = operator with parentheses for array membership
    # This will return games that have this genre, even if they have other genres too
    # The correct syntax is: genres = (6) for Fighting genre
    where_clause = "where genres = (#{genre_id}) & cover != null;"
    
    Rails.logger.info("Fetching games for genre: #{genre} (ID: #{genre_id}) with query: #{where_clause}")
    
    games = IgdbService.fetch_games(
      query: "",
      fields: fields,
      where_clause: where_clause,
      limit: 500  # Fetch more to ensure we have enough games to sort and return 300
    )
    

    if games && games.any?
      GameCacheService.upsert_many_from_igdb(games)
      Rails.logger.info("Found #{games.length} games for genre: #{genre} (ID: #{genre_id})")
      sorted_games = games.sort_by do |game|
        # Use aggregated_rating (0-100 scale) if available, otherwise use rating (0-100 scale)
        rating = game["aggregated_rating"] || game["rating"] || -1 # -1 for games without ratings
        -rating # Negative for descending order
      end
      
      # Return top 300 most popular games (for mobile app)
      result = sorted_games.take(300)
      Rails.logger.info("Returning #{result.length} games for genre: #{genre}")
      render json: result
    else
      # Log for debugging
      Rails.logger.warn("No games found for genre: #{genre} (ID: #{genre_id}) - games was: #{games.inspect}")
      render json: [], status: :ok
    end
  end

  def by_year
    year = params[:year]&.to_i
    return render json: { error: 'Missing or invalid year parameter' }, status: :bad_request if year.blank? || year < 1970 || year > 2100

    # Calculate Unix timestamps for the year
    start_timestamp = Time.utc(year, 1, 1).to_i
    end_timestamp = Time.utc(year + 1, 1, 1).to_i - 1

    fields = "id, name, cover.image_id, first_release_date, rating, aggregated_rating, summary"
    where_clause = "where first_release_date >= #{start_timestamp} & first_release_date < #{end_timestamp} & cover != null & rating != null;"
    
    games = IgdbService.fetch_games(
      query: "",
      fields: fields,
      where_clause: where_clause,
      limit: 200
    )

    if games && games.any?
      GameCacheService.upsert_many_from_igdb(games)
      sorted_games = games.sort_by do |game|
        rating = game["aggregated_rating"] || game["rating"] || 0
        -rating
      end
      render json: sorted_games.take(300)
    else
      render json: [], status: :ok
    end
  end

  def by_console
    console_name = params[:console]
    return render json: { error: 'Missing console parameter' }, status: :bad_request if console_name.blank?

    # Map console name to IGDB platform ID
    platform_map = {
      'PlayStation 5' => 167,
      'Xbox Series X' => 169,
      'Nintendo Switch' => 130,
      'PlayStation 4' => 48,
      'Xbox One' => 49,
      'PC' => 6,
      'PlayStation 3' => 9,
      'Xbox 360' => 12,
      'Wii U' => 41,
      'Nintendo 3DS' => 37,
      'PlayStation Vita' => 46,
      'Wii' => 5
    }

    platform_id = platform_map[console_name] || platform_map[console_name.strip]
    return render json: [], status: :ok unless platform_id

    fields = "id, name, cover.image_id, first_release_date, rating, aggregated_rating, summary"
    where_clause = "where platforms = (#{platform_id}) & cover != null & rating != null;"
    
    games = IgdbService.fetch_games(
      query: "",
      fields: fields,
      where_clause: where_clause,
      limit: 500  # Fetch more to ensure we have enough games to sort and return 300
    )

    if games && games.any?
      GameCacheService.upsert_many_from_igdb(games)
      sorted_games = games.sort_by do |game|
        rating = game["aggregated_rating"] || game["rating"] || 0
        -rating
      end
      render json: sorted_games.take(300)
    else
      render json: [], status: :ok
    end
  end

  def by_decade
    start_year = params[:start_year]&.to_i
    end_year = params[:end_year]&.to_i
    return render json: { error: 'Missing or invalid year parameters' }, status: :bad_request if start_year.blank? || end_year.blank? || start_year < 1970 || end_year > 2100

    # Calculate Unix timestamps for the decade range
    start_timestamp = Time.utc(start_year, 1, 1).to_i
    end_timestamp = Time.utc(end_year + 1, 1, 1).to_i - 1

    fields = "id, name, cover.image_id, first_release_date, rating, aggregated_rating, summary"
    where_clause = "where first_release_date >= #{start_timestamp} & first_release_date <= #{end_timestamp} & cover != null & rating != null;"
    
    games = IgdbService.fetch_games(
      query: "",
      fields: fields,
      where_clause: where_clause,
      limit: 500  # Fetch more to ensure we have enough games to sort and return 300
    )

    if games && games.any?
      GameCacheService.upsert_many_from_igdb(games)
      sorted_games = games.sort_by do |game|
        rating = game["aggregated_rating"] || game["rating"] || 0
        -rating
      end
      render json: sorted_games.take(300)
    else
      render json: [], status: :ok
    end
  end

  def most_popular_igdb
    # Fetch most popular games directly from IGDB (not from app database)
    # Use IGDB's native sorting by popularity field
    fields = "id, name, cover.image_id, first_release_date, rating, aggregated_rating, summary, popularity, follows"
    
    # Get games with covers - no other restrictions to get maximum results
    where_clause = "where cover != null;"
    
    # Use IGDB's native sorting - sort by popularity descending
    sort_clause = "popularity desc"
    
    Rails.logger.info("Fetching most popular games from IGDB with query: #{where_clause}, sort: #{sort_clause}")
    
    games = IgdbService.fetch_games(
      query: "",
      fields: fields,
      where_clause: where_clause,
      limit: 100,
      sort: sort_clause
    )

    if games && games.any?
      GameCacheService.upsert_many_from_igdb(games)
      Rails.logger.info("Found #{games.length} popular games from IGDB")
      render json: games
    else
      Rails.logger.warn("No popular games found from IGDB, trying fallback without sort")
      # Fallback: try without sort and sort in Ruby
      games = IgdbService.fetch_games(
        query: "",
        fields: fields,
        where_clause: where_clause,
        limit: 500
      )
      
      if games && games.any?
        GameCacheService.upsert_many_from_igdb(games)
        sorted_games = games.sort_by do |game|
          popularity = game["popularity"] || 0
          follows = game["follows"] || 0
          rating = game["aggregated_rating"] || game["rating"] || 0
          [-popularity, -follows, -rating]
        end
        render json: sorted_games.take(100)
      else
        render json: [], status: :ok
      end
    end
  end

  def most_anticipated_igdb
    # Fetch most anticipated games directly from IGDB (not from app database)
    # These are games with future release dates, sorted by hypes (most anticipated)
    current_timestamp = Time.now.to_i
    future_timestamp = Time.now.to_i + (365 * 24 * 60 * 60 * 5) # 5 years in the future
    
    fields = "id, name, cover.image_id, first_release_date, rating, aggregated_rating, summary, hypes, follows"
    
    # Get games with future release dates and covers
    # Use hypes field which indicates how many people are hyped/anticipating the game
    where_clause = "where cover != null & first_release_date > #{current_timestamp} & first_release_date < #{future_timestamp};"
    
    # Use IGDB's native sorting - sort by hypes descending (most hyped first)
    sort_clause = "hypes desc"
    
    Rails.logger.info("Fetching most anticipated games from IGDB with query: #{where_clause}, sort: #{sort_clause}")
    Rails.logger.info("Current timestamp: #{current_timestamp}, Future timestamp: #{future_timestamp}")
    
    games = IgdbService.fetch_games(
      query: "",
      fields: fields,
      where_clause: where_clause,
      limit: 100,
      sort: sort_clause
    )

    if games && games.any?
      GameCacheService.upsert_many_from_igdb(games)
      Rails.logger.info("Found #{games.length} anticipated games from IGDB")
      render json: games
    else
      Rails.logger.warn("No anticipated games found from IGDB, trying fallback without sort")
      # Fallback: try without sort and sort in Ruby
      games = IgdbService.fetch_games(
        query: "",
        fields: fields,
        where_clause: where_clause,
        limit: 500
      )
      
      if games && games.any?
        GameCacheService.upsert_many_from_igdb(games)
        sorted_games = games.sort_by do |game|
          hypes = game["hypes"] || 0
          follows = game["follows"] || 0
          release_date = game["first_release_date"] || 9999999999
          [-hypes, -follows, release_date]
        end
        render json: sorted_games.take(100)
      else
        render json: [], status: :ok
      end
    end
  end
end