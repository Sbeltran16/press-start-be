require 'set'

module Api
  class ExternalGamesController < ApplicationController
  skip_before_action :authenticate_user!

    def show
      igdb_game_id = params[:id]

      # Use cached external_links from game cache when present (same shape: type, uid, url)
      cached = GameCacheService.find_by_igdb_id(igdb_game_id)
      if cached && cached["external_links"].present?
        links = cached["external_links"].map { |h| h.transform_keys(&:to_sym) }
        return render json: links
      end

      formatted = fetch_and_format_external_links(igdb_game_id)
      unique_links = {}
      formatted.each { |link| unique_links[link[:type]] ||= link }
      render json: unique_links.values
    end

    private

    def fetch_and_format_external_links(igdb_game_id)
      external_links = IgdbService.fetch_external_links(igdb_game_id)
      allowed_sources = [1, 31, 36, 11, 130, 13]
      found_links_by_type = {}
      found_urls = Set.new

      external_links.filter_map do |entry|
        next unless allowed_sources.include?(entry["external_game_source"])
        url = entry["url"].presence || build_platform_url(entry["external_game_source"], entry["uid"])
        next unless url.present?
        normalized_url = url.gsub(/\/+$/, "").split("?").first.split("#").first
        next if found_urls.include?(normalized_url)
        type = platform_type(entry["external_game_source"])
        next if found_links_by_type[type]
        found_links_by_type[type] = true
        found_urls.add(normalized_url)
        { type: type, uid: entry["uid"], url: url }
      end
    end

    def platform_type(source)
      {
        1 => "steam",
        31 => "xbox",
        36 => "playstation",
        11 => "epic",
        130 => "nintendo",
        13 => "gog",
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
      when 11
        "https://www.epicgames.com/store/en-US/p/#{uid}"
      when 130
        "https://www.nintendo.com/store/products/#{uid}/"
      when 13
        "https://www.gog.com/game/#{uid}"
      else
        nil
      end
    end
    
  end
end
