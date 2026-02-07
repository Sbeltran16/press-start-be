class IgdbService
  def self.fetch_games(query:, fields:, where_clause:, limit: 12, sort: nil)
    token = fetch_access_token
    uri = URI("https://api.igdb.com/v4/games")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path)
    request["Client-ID"] = ENV['TWITCH_CLIENT_ID']
    request["Authorization"] = "Bearer #{token}"
    request["Content-Type"] = "text/plain"

    body = <<~BODY
      fields #{fields};
      #{query}
      #{where_clause}
      #{sort ? "sort #{sort};" : ""}
      limit #{limit};
    BODY

    request.body = body.strip
    response = http.request(request)

    if response.code.to_i == 200
      parsed = JSON.parse(response.body)
      Rails.logger.info("IGDB Success: Fetched #{parsed.length} games")
      parsed
    else
      Rails.logger.error("IGDB Error: HTTP #{response.code} - #{response.body}")
      nil
    end
  rescue => e
    Rails.logger.error("IGDB Error: #{e.message}")
    Rails.logger.error("IGDB Error Backtrace: #{e.backtrace.first(5).join("\n")}")
    nil
  end

  def self.fetch_access_token
    unless ENV["TWITCH_CLIENT_ID"] && ENV["TWITCH_CLIENT_SECRET"]
      Rails.logger.error("IGDB Error: Missing TWITCH_CLIENT_ID or TWITCH_CLIENT_SECRET")
      raise "IGDB credentials not configured"
    end

    uri = URI("https://id.twitch.tv/oauth2/token")
    response = Net::HTTP.post_form(uri, {
      client_id: ENV["TWITCH_CLIENT_ID"],
      client_secret: ENV["TWITCH_CLIENT_SECRET"],
      grant_type: "client_credentials"
    })
    
    if response.code.to_i == 200
      token_data = JSON.parse(response.body)
      token_data["access_token"]
    else
      Rails.logger.error("IGDB Token Error: HTTP #{response.code} - #{response.body}")
      raise "Failed to get IGDB access token"
    end
  rescue => e
    Rails.logger.error("IGDB Token Error: #{e.message}")
    raise
  end

  def self.fetch_steam_url(igdb_game_id)
    token = fetch_access_token
    uri = URI("https://api.igdb.com/v4/external_games")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path)
    request["Client-ID"] = ENV['TWITCH_CLIENT_ID']
    request["Authorization"] = "Bearer #{token}"
    request["Content-Type"] = "text/plain"

    body = <<~BODY
      fields uid;
      where game = #{igdb_game_id} & external_game_source = 1;
      limit 1;
    BODY

    request.body = body.strip
    response = http.request(request)

    if response.code.to_i == 200
      json = JSON.parse(response.body)
      uid = json.first&.dig("uid")
      return "https://store.steampowered.com/app/#{uid}/" if uid
    end

    nil
  rescue => e
    Rails.logger.error("IGDB Steam URL Error: #{e.message}")
    nil
  end

  def self.fetch_external_links(igdb_game_id)
    token = fetch_access_token
    uri = URI("https://api.igdb.com/v4/external_games")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path)
    request["Client-ID"] = ENV['TWITCH_CLIENT_ID']
    request["Authorization"] = "Bearer #{token}"
    request["Content-Type"] = "text/plain"

    body = <<~BODY
      fields uid, url, external_game_source;
      where game = #{igdb_game_id} & external_game_source != null;
      limit 50;
    BODY

    request.body = body.strip
    response = http.request(request)

    return JSON.parse(response.body) if response.code.to_i == 200

    []
  rescue => e
    Rails.logger.error("IGDB External Links Error: #{e.message}")
    []
  end

  def self.fetch_news(limit: nil)
    # IGDB Pulse News has been discontinued, so we'll parse RSS feeds manually using Nokogiri
    require 'net/http'
    require 'nokogiri'
    
    news_items = []
    
    # Gaming news RSS feeds - multiple feeds per source to get more articles
    rss_feeds = [
      { url: 'https://www.ign.com/feeds/games/all', name: 'IGN' },
      { url: 'https://www.ign.com/feeds/news', name: 'IGN' },
      { url: 'https://www.gamespot.com/feeds/news/', name: 'GameSpot' },
      { url: 'https://www.gamespot.com/feeds/games/', name: 'GameSpot' },
      { url: 'https://www.polygon.com/rss/index.xml', name: 'Polygon' },
      { url: 'https://www.polygon.com/rss/games/index.xml', name: 'Polygon' },
      { url: 'https://kotaku.com/rss', name: 'Kotaku' },
      { url: 'https://www.pcgamer.com/rss/', name: 'PC Gamer' },
      { url: 'https://www.eurogamer.net/feed', name: 'Eurogamer' },
      { url: 'https://www.gameinformer.com/feeds/thefeed.aspx', name: 'Game Informer' }
    ]
    
    # Fetch all feeds in parallel using threads for better performance
    threads = rss_feeds.map do |feed|
      Thread.new do
        begin
          uri = URI(feed[:url])
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.read_timeout = 5  # Reduced timeout for faster failure
          http.open_timeout = 5  # Reduced timeout for faster failure
          
          request_path = uri.path.empty? ? '/' : uri.path
          request_path += "?#{uri.query}" if uri.query
          
          response = http.get(request_path, { 'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36' })
          
          if response.code.to_i == 200
            doc = Nokogiri::XML(response.body)
            # Fetch all items from each feed (RSS feeds typically have 20-50 items)
            # Don't limit per feed - get everything available
            
            feed_items = []
            doc.xpath('//item').each do |item|
              title_elem = item.at_xpath('title')
              title = title_elem ? title_elem.text.to_s.strip : 'Untitled'
              
              desc_elem = item.at_xpath('description')
              description = desc_elem ? desc_elem.text.to_s.strip : ''
              
              # Extract actual product URLs from description HTML
              product_urls = extract_product_urls(description)
              
              link_elem = item.at_xpath('link')
              link = link_elem ? link_elem.text.to_s.strip : ''
              
              pub_date_elem = item.at_xpath('pubDate')
              pub_date = pub_date_elem ? pub_date_elem.text.to_s : nil
              
              # Parse date
              published_at = begin
                Time.parse(pub_date).to_i if pub_date && !pub_date.empty?
              rescue
                Time.now.to_i
              end || Time.now.to_i
              
              # Try multiple methods to extract image
              image_url = nil
              
              # Method 1: Check for media:content (common in RSS feeds)
              media_content = item.at_xpath('media:content', 'media' => 'http://search.yahoo.com/mrss/')
              if media_content && media_content['url']
                image_url = media_content['url']
              end
              
              # Method 2: Check for enclosure with image type
              if image_url.nil?
                enclosure = item.at_xpath('enclosure')
                if enclosure && enclosure['type'] && enclosure['type'].start_with?('image/')
                  image_url = enclosure['url']
                end
              end
              
              # Method 3: Check for media:thumbnail
              if image_url.nil?
                media_thumbnail = item.at_xpath('media:thumbnail', 'media' => 'http://search.yahoo.com/mrss/')
                if media_thumbnail && media_thumbnail['url']
                  image_url = media_thumbnail['url']
                end
              end
              
              # Method 4: Extract from description HTML
              if image_url.nil?
                image_url = extract_image_from_html(description)
              end
              
              # Generate ID from link
              item_id = link.empty? ? rand(1000000) : link.hash.abs
              
              feed_items << {
                id: item_id,
                title: title,
                summary: strip_html_tags(description),
                url: link,
                image_url: image_url,
                published_at: published_at,
                author: nil,
                source: feed[:name],
                product_urls: product_urls
              }
            end
            feed_items
          else
            []
          end
        rescue => e
          Rails.logger.error("RSS Feed Error (#{feed[:url]}): #{e.message}")
          Rails.logger.error("Backtrace: #{e.backtrace.first(3).join("\n")}")
          []
        end
      end
    end
    
    # Collect results from all threads
    threads.each do |thread|
      thread.join
      feed_items = thread.value
      news_items.concat(feed_items) if feed_items.is_a?(Array)
    end
    
    # Remove duplicates based on URL (same article from different feeds)
    unique_items = news_items.uniq { |item| item[:url] }
    
    # Sort by published_at (newest first)
    sorted_items = unique_items.sort_by { |item| -item[:published_at] }
    
    # Only apply limit if specified (for dashboard use)
    limit ? sorted_items.first(limit) : sorted_items
  rescue => e
    Rails.logger.error("Gaming News Error: #{e.message}")
    Rails.logger.error("Backtrace: #{e.backtrace.first(5).join("\n")}")
    []
  end
  
  def self.extract_image_from_html(html)
    return nil unless html
    
    # Look for img tags with src attribute
    img_match = html.match(/<img[^>]+src=["']([^"']+)["']/i)
    if img_match
      img_url = img_match[1]
      # Clean up the URL (remove query params that might be for sizing)
      img_url = img_url.split('?').first if img_url.include?('?')
      return img_url if img_url.match?(/\.(jpg|jpeg|png|gif|webp)/i)
    end
    
    # Look for data-src (lazy loaded images)
    data_src_match = html.match(/<img[^>]+data-src=["']([^"']+)["']/i)
    if data_src_match
      img_url = data_src_match[1]
      img_url = img_url.split('?').first if img_url.include?('?')
      return img_url if img_url.match?(/\.(jpg|jpeg|png|gif|webp)/i)
    end
    
    # Look for og:image meta tag
    og_match = html.match(/property=["']og:image["'][^>]+content=["']([^"']+)["']/i)
    return og_match[1] if og_match
    
    # Look for meta name="image"
    meta_match = html.match(/<meta[^>]+name=["']image["'][^>]+content=["']([^"']+)["']/i)
    return meta_match[1] if meta_match
    
    nil
  end
  
  def self.extract_product_urls(html)
    return {} unless html
    
    urls = {}
    
    # Common retailer domains mapped to their display names
    retailer_domains = {
      'amazon.com' => 'Amazon',
      'amzn.to' => 'Amazon',
      'gamestop.com' => 'GameStop',
      'bestbuy.com' => 'Best Buy',
      'target.com' => 'Target',
      'walmart.com' => 'Walmart',
      'steampowered.com' => 'Steam',
      'epicgames.com' => 'Epic Games',
      'playstation.com' => 'PlayStation Store',
      'xbox.com' => 'Xbox Store',
      'nintendo.com' => 'Nintendo eShop'
    }
    
    # First, look for href attributes in links (most reliable)
    html.scan(/href=["'](https?:\/\/[^"']+)["']/i) do |match|
      url = match[0]
      retailer_domains.each do |domain, name|
        if url.include?(domain)
          # Check if it's a product URL (not just homepage or search)
          is_homepage = url.match?(/#{domain}\/?$/) || url.match?(/#{domain}\/\?/)
          is_search = url.include?('/search') || url.include?('/s?')
          
          unless is_homepage || is_search
            # It's likely a product page - use the first one found for each retailer
            urls[name] = url unless urls[name]
            break
          end
        end
      end
    end
    
    # Also extract standalone URLs from text (fallback)
    url_pattern = /https?:\/\/(?:www\.)?([^\s<>"']+)/i
    html.scan(url_pattern) do |match|
      full_url = match[0].start_with?('http') ? match[0] : "https://#{match[0]}"
      retailer_domains.each do |domain, name|
        if full_url.include?(domain) && !urls[name]
          is_homepage = full_url.match?(/#{domain}\/?$/) || full_url.match?(/#{domain}\/\?/)
          is_search = full_url.include?('/search') || full_url.include?('/s?')
          
          unless is_homepage || is_search
            urls[name] = full_url
            break
          end
        end
      end
    end
    
    urls
  end
  
  def self.strip_html_tags(html)
    return '' unless html
    
    # Replace block-level elements with newlines to preserve paragraph structure
    html = html.gsub(/<\/?(p|div|br|li|ul|ol|h[1-6])[^>]*>/i, "\n")
    # Replace other HTML tags
    html = html.gsub(/<[^>]*>/, '')
    # Decode HTML entities
    html = html.gsub(/&nbsp;/, ' ')
    html = html.gsub(/&amp;/, '&')
    html = html.gsub(/&lt;/, '<')
    html = html.gsub(/&gt;/, '>')
    html = html.gsub(/&quot;/, '"')
    html = html.gsub(/&#39;/, "'")
    html = html.gsub(/&apos;/, "'")
    # Clean up multiple newlines and whitespace
    html = html.gsub(/\n\s*\n\s*\n+/, "\n\n")
    html = html.gsub(/[ \t]+/, ' ')
    html.strip
  end

end
