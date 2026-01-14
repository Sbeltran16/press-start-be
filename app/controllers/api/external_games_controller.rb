require 'set'

module Api
  class ExternalGamesController < ApplicationController
  skip_before_action :authenticate_user!

    def show
      igdb_game_id = params[:id]
      external_links = IgdbService.fetch_external_links(igdb_game_id)

      # Support multiple platforms: Steam, Xbox, PlayStation, Epic Games, Nintendo, GOG
      allowed_sources = [1, 31, 36, 11, 130, 13]

      # Map to store links found from external_games (by type to prevent duplicates)
      found_links_by_type = {}
      found_urls = Set.new  # Track URLs to prevent duplicates
      
      formatted = external_links.map do |entry|
        next unless allowed_sources.include?(entry["external_game_source"])

        # Use URL from IGDB if available, otherwise construct it from UID
        url = entry["url"].presence || build_platform_url(entry["external_game_source"], entry["uid"])

        next unless url.present?
        
        # Normalize URL for comparison (remove trailing slashes, query params)
        normalized_url = url.gsub(/\/+$/, '').split('?').first.split('#').first
        
        # Skip if we've already seen this URL (normalized)
        next if found_urls.include?(normalized_url)

        type = platform_type(entry["external_game_source"])
        
        # Skip if we already have a link for this type
        next if found_links_by_type[type]
        
        found_links_by_type[type] = true
        found_urls.add(normalized_url)
        
        {
          type: type,
          uid: entry["uid"],
          url: url,
        }
      end.compact

      # Final deduplication: remove any remaining duplicates by type
      unique_links = {}
      formatted.each do |link|
        # Keep the first occurrence of each type
        unique_links[link[:type]] ||= link
      end

      render json: unique_links.values
    end

    private

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
