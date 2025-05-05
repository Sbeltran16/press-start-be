class GamesController < ApplicationController
  require 'net/http'
  require 'json'

  CLIENT_ID = ENV['TWITCH_CLIENT_ID']
  CLIENT_SECRET = ENV['TWITCH_CLIENT_SECRET']

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
    fields name, total_rating_count, cover.image_id, artworks.image_id, updated_at, summary, release_dates, rating, genres.name;
    where first_release_date > #{(Time.now - 14.days).to_i};
    sort rating asc;
    limit 6;
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
