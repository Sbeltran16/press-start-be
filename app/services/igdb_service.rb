class IgdbService
  def self.fetch_games(query:, fields:, where_clause:, limit: 12)
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
      limit #{limit};
    BODY

    request.body = body.strip
    response = http.request(request)

    JSON.parse(response.body) if response.code.to_i == 200
  rescue => e
    Rails.logger.error("IGDB Error: #{e.message}")
    nil
  end

  def self.fetch_access_token
    uri = URI("https://id.twitch.tv/oauth2/token")
    response = Net::HTTP.post_form(uri, {
      client_id: ENV["TWITCH_CLIENT_ID"],
      client_secret: ENV["TWITCH_CLIENT_SECRET"],
      grant_type: "client_credentials"
    })
    JSON.parse(response.body)["access_token"]
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
  

end
