Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "http://localhost:3000", "https://press-start-beta.vercel.app", "http://pressstart.gg"

    resource "*",
      headers: :any,
      expose: ['Authorization'],  # <-- just one version with capital A
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end
