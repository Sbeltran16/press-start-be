module Api
  class ExternalGamesController < ApplicationController
    def show
      igdb_game_id = params[:id]
      external_links = IgdbService.fetch_external_links(igdb_game_id)

      allowed_sources = [1, 31, 36]

      formatted = external_links.map do |entry|
        next unless allowed_sources.include?(entry["external_game_source"])

        url = entry["url"].presence || build_platform_url(entry["external_game_source"], entry["uid"])

        next unless url.present?

        {
          type: platform_type(entry["external_game_source"]),
          uid: entry["uid"],
          url: url,
        }
      end.compact

      render json: formatted
    end

    private

    def platform_type(source)
      {
        1 => "steam",
        31 => "xbox",
        36 => "playstation"
      }[source] || "other"
    end

    def build_platform_url(source, uid)
      return nil unless uid

      case source
      when 1
        "https://store.steampowered.com/app/#{uid}/"
      when 31
        "https://www.xbox.com/en-US/games/store/#{uid}"
      when 36
        "https://store.playstation.com/en-us/product/#{uid}"
      else
        nil
      end
    end
  end
end
