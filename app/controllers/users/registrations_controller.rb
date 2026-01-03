class Users::RegistrationsController < Devise::RegistrationsController
  include RackSessionFix
  skip_before_action :authenticate_user!
  respond_to :json
  private

  def respond_with(resource, _opts = {})
    if request.method == "POST" && resource.persisted?
      # Send confirmation email
      resource.send_confirmation_instructions unless resource.confirmed?
      
      # Don't generate JWT token yet - user needs to confirm email first
      render json: {
        status: {code: 200, message: "Signed up successfully. Please check your email to confirm your account."},
        data: UserSerializer.new(resource).serializable_hash[:data][:attributes],
        email_confirmed: resource.confirmed?
      }, status: :ok
    elsif request.method == "DELETE"
      render json: {
        status: { code: 200, message: "Account deleted successfully."}
      }, status: :ok
    else
      # Log errors for debugging
      Rails.logger.error "User creation failed: #{resource.errors.full_messages.inspect}"
      Rails.logger.error "User attributes: #{resource.attributes.inspect}"
      Rails.logger.error "User valid?: #{resource.valid?}"
      
      render json: {
        status: {code: 422, message: "User couldn't be created successfully. #{resource.errors.full_messages.to_sentence}"},
        errors: resource.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
end

