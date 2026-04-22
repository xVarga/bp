Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # In development, allow all origins.
    # In production, replace "*" with your actual Flutter app domain or IP.
    origins "*"

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ["Authorization"]
  end
end
