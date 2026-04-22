class ApplicationController < ActionController::API
  SECRET_KEY = ENV.fetch("JWT_SECRET", "change_this_secret_in_production")

  def authenticate_user!
    token = request.headers["Authorization"]&.split(" ")&.last
    if token
      payload = decode_token(token)
      @current_user = User.find(payload["user_id"]) if payload
    end

    render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def encode_token(user_id)
    payload = { user_id: user_id, exp: 30.days.from_now.to_i }
    JWT.encode(payload, SECRET_KEY, "HS256")
  end

  def decode_token(token)
    JWT.decode(token, SECRET_KEY, true, algorithm: "HS256").first
  rescue JWT::DecodeError
    nil
  end
end
