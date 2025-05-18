class Users::SessionsController < Devise::SessionsController
  include RackSessionFix
  skip_before_action :authenticate_user!
  respond_to :json

  private

  def respond_with(current_user, _opts = {})
  token = Warden::JWTAuth::UserEncoder.new.call(current_user, :user, nil).first
  Rails.logger.info "Generated JWT token: #{token}"

  response.set_header('Authorization', "Bearer #{token}")
  Rails.logger.info "Response headers: #{response.headers.to_h}"

  render json: {
    status: { code: 200, message: 'Logged in successfully.' },
    data: UserSerializer.new(current_user).serializable_hash[:data][:attributes]
  }, status: :ok
end


  def respond_to_on_destroy
    if request.headers['Authorization'].present?
      jwt_payload = JWT.decode(
        request.headers['Authorization'].split(' ').last,
        Rails.application.credentials.devise_jwt_secret_key!
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
