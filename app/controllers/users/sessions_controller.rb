class Users::SessionsController < Devise::SessionsController
  include RackSessionFix
  skip_before_action :authenticate_user!
  respond_to :json

  private

  def respond_with(current_user, _opts = {})
    # Check if email is confirmed
    unless current_user.confirmed?
      render json: {
        status: { code: 403, message: 'Please confirm your email address before logging in.' },
        email_confirmed: false,
        email: current_user.email
      }, status: :forbidden
      return
    end

    # Determine expiration time based on user preferences
    expiration_time = determine_expiration_time

    # Generate JWT token with custom expiration
    token = generate_jwt_token(current_user, expiration_time)
    Rails.logger.info "Generated JWT token with expiration: #{expiration_time} seconds"

    response.set_header('Authorization', "Bearer #{token}")
    Rails.logger.info "Response headers: #{response.headers.to_h}"

    render json: {
      status: { code: 200, message: 'Logged in successfully.' },
      data: UserSerializer.new(current_user).serializable_hash[:data][:attributes]
    }, status: :ok
  end

  def determine_expiration_time
    # Get session preferences from request params
    user_params = params[:user] || {}
    remember_me = user_params[:remember_me].to_s == 'true' || user_params[:remember_me] == true

    Rails.logger.info "Session preferences - remember_me: #{remember_me}"

    if remember_me
      # 30 days
      30.days.to_i
    else
      # Default: 24 hours
      24.hours.to_i
    end
  end

  def generate_jwt_token(user, expiration_time)
    payload = {
      sub: user.id.to_s,
      scp: 'user',
      exp: Time.now.to_i + expiration_time,
      iat: Time.now.to_i,
      jti: user.jti
    }

    # Use the same secret as devise-jwt (from credentials)
    secret = Rails.application.credentials.fetch(:secret_key_base)
    JWT.encode(payload, secret, 'HS256')
  end

  def respond_to_on_destroy
    if request.headers['Authorization'].present?
      jwt_payload = JWT.decode(
        request.headers['Authorization'].split(' ').last,
        Rails.application.credentials.fetch(:secret_key_base)
      ).first
      current_user = User.find(jwt_payload['sub'])
    end

    if current_user
      render json: {
        status: 200,
        message: "Logged out successfully"
      }, status: :ok
    else
      render json: {
        status: 401,
        message: "Couldn't find an active session."
      }, status: :unauthorized
    end
  end
end
