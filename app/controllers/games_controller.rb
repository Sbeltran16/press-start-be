class GamesController < ApplicationController
  require 'net/http'
  require 'json'

  CLIENT_ID = ENV['TWITCH_CLIENT_ID']
  CLIENT_SECRET = ENV['TWITCH_CLIENT_SECRET']

 # Game Index
  def index
    if params[:name]
      @games = Game.where("name ILIKE ?", "%#{params[:name]}%")
    else
      @games = Game.all
    end

    render json: @games
  end

  # Top Popular Games
  def top
    token = fetch_access_token

    uri = URI("https://api.igdb.com/v4/games")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path)
    request["Client-ID"] = CLIENT_ID
    request["Authorization"] = "bearer #{token}"
    request["Content-Type"] = "text/plain"
    request.body = <<~BODY
    fields name, hypes, cover.image_id, artworks.image_id, updated_at, summary, release_dates, rating, genres.name;
    where first_release_date > #{(Time.now - 30.days).to_i}
      & hypes != null;
    sort hypes desc;
    limit 12;
  BODY

    response = http.request(request)

    Rails.logger.debug("IGDB API Response Code: #{response.code}")
    Rails.logger.debug("IGDB API Response Body: #{response.body}")

    if response.code.to_i == 200
      render json: JSON.parse(response.body)
    else
      render json: { error: "Failed to fetch games", status: response.code, response_body: response.body }, status: :bad_request
    end
  end


  # Show games by name
  def show_by_name
    name = params[:name]

    if name.blank?
      render json: { error: 'Missing name parameter' }, status: :bad_request and return
    end

    decoded_name = CGI.unescape(name)
    Rails.logger.info "Looking up game: #{decoded_name}"

    token = fetch_access_token

    uri = URI("https://api.igdb.com/v4/games")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path)
    request["Client-ID"] = CLIENT_ID
    request["Authorization"] = "Bearer #{token}"
    request["Content-Type"] = "text/plain"
    request.body = <<~BODY
      fields name, cover.image_id, summary, rating, genres.name, first_release_date, artworks.image_id, platforms, release_dates, screenshots.image_id, storyline, videos.video_id, videos.name, involved_companies.company.name;
      search "#{decoded_name}";
      limit 1;
    BODY

    response = http.request(request)

    Rails.logger.debug("IGDB Search Response: #{response.body}")

    if response.code.to_i == 200
      games = JSON.parse(response.body)
      if games.any?
        render json: games.first
      else
        render json: { error: "Game not found" }, status: :not_found
      end
    else
      render json: { error: "Failed to fetch game", status: response.code, body: response.body }, status: :bad_request
    end
  end

  # Show multiple games by name (for search results page)
def search_by_name
  name = params[:name]

  if name.blank?
    render json: { error: 'Missing name parameter' }, status: :bad_request and return
  end

  decoded_name = CGI.unescape(name)
  Rails.logger.info "Searching for games: #{decoded_name}"

  token = fetch_access_token

  uri = URI("https://api.igdb.com/v4/games")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(uri.path)
  request["Client-ID"] = CLIENT_ID
  request["Authorization"] = "Bearer #{token}"
  request["Content-Type"] = "text/plain"
  request.body = <<~BODY
    fields name, cover.image_id, summary, rating, genres.name, first_release_date, artworks.image_id, platforms, release_dates, screenshots.image_id, storyline, videos.video_id, videos.name, involved_companies.company.name;
    search "#{decoded_name}";
    limit 100;
  BODY

  response = http.request(request)

  Rails.logger.debug("IGDB Search Response: #{response.body}")

  if response.code.to_i == 200
    games = JSON.parse(response.body)
    if games.any?
      render json: games
    else
      render json: { error: "No games found" }, status: :not_found
    end
  else
    render json: { error: "Failed to fetch games", status: response.code, body: response.body }, status: :bad_request
  end
end


  private
  def fetch_access_token
    uri = URI("https://id.twitch.tv/oauth2/token")

    response = Net::HTTP.post_form(uri, {
      client_id: ENV["TWITCH_CLIENT_ID"],
      client_secret: ENV["TWITCH_CLIENT_SECRET"],
      grant_type: "client_credentials"
    })

    Rails.logger.debug("Twitch Token Response: #{response.body}")

    response_data = JSON.parse(response.body)

    Rails.logger.debug("Twitch Token Parsed Response: #{response_data}")

    access_token = response_data["access_token"]
    Rails.logger.debug("Twitch Token: #{access_token}")

    access_token
  end
end
