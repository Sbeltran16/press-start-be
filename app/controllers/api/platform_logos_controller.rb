# app/controllers/api/platform_logos_controller.rb
module Api
  class PlatformLogosController < ApplicationController
    PLATFORM_IDS = [6, 130, 49, 169, 48, 167]

    # Simple in-memory cache for logos
    @@logos_cache = nil
    @@last_fetch_time = nil

    def index
      # Refresh cache every 24 hours (or adjust as needed)
      if @@logos_cache.nil? || (@@last_fetch_time && Time.now - @@last_fetch_time > 24.hours)
        @@logos_cache = fetch_platform_logos
        @@last_fetch_time = Time.now
      end

      render json: @@logos_cache || []
    end

    private

 # in platform_logos_controller.rb

    def fetch_platform_logos
      token = IgdbService.fetch_access_token
      uri = URI("https://api.igdb.com/v4/platforms")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.path)
      request["Client-ID"] = ENV['TWITCH_CLIENT_ID']
      request["Authorization"] = "Bearer #{token}"
      request["Content-Type"] = "text/plain"

      body = <<~BODY
        fields id, name, platform_logo.image_id, platform_logo.url, platform_logo.width, platform_logo.height, platform_logo.alpha_channel;
        where id = (6, 130, 49, 169, 48, 167);
      BODY

      request.body = body.strip
      response = http.request(request)

      if response.code.to_i == 200
        json = JSON.parse(response.body)

        Rails.logger.info("Fetched platform data: #{json}")

        json.each_with_object({}) do |platform, hash|
          next unless platform["platform_logo"]

          hash[platform["id"]] = {
            image_id: platform["platform_logo"]["image_id"],
            url: platform["platform_logo"]["url"],
            width: platform["platform_logo"]["width"],
            height: platform["platform_logo"]["height"],
            alpha_channel: platform["platform_logo"]["alpha_channel"]
          }
        end
      else
        Rails.logger.error("IGDB API Error: #{response.body}")
        []
      end
    rescue => e
      Rails.logger.error("IGDB Platform Logos Error: #{e.message}")
      []
    end
  end
end
