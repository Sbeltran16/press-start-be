class Users::RegistrationsController < Devise::RegistrationsController
  include RackSessionFix
  skip_before_action :authenticate_user!
  respond_to :json
  private

  def respond_with(resource, _opts = {})
    if request.method == "POST" && resource.persisted?
      # Send confirmation email with error handling
      # Only send if SMTP is configured
      if ENV['SMTP_USERNAME'].present? && ENV['SMTP_PASSWORD'].present?
        begin
          resource.send_confirmation_instructions unless resource.confirmed?
        rescue => e
          # Log the error but don't fail the signup
          Rails.logger.error "Failed to send confirmation email: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          # Continue with signup even if email fails
        end
      else
        Rails.logger.warn "SMTP not configured - skipping confirmation email for user #{resource.id}"
      end
      
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

