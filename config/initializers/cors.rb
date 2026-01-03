Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "http://localhost:3000", "https://press-start-beta.vercel.app", "https://pressstart.gg",
    "https://www.pressstart.gg"

    resource "*",
      headers: :any,
      expose: ['Authorization'],  # <-- just one version with capital A
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end

  # Allow all origins for mobile app development (you can restrict this in production)
  allow do
    origins "*"  # Allow all origins for mobile apps

    resource "*",
      headers: :any,
      expose: ['Authorization'],
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: false  # Mobile apps don't use cookies
  end
end
