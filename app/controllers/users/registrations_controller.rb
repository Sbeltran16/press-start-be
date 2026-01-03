class Users::RegistrationsController < Devise::RegistrationsController
  include RackSessionFix
  skip_before_action :authenticate_user!
  skip_before_action :check_email_confirmation
  respond_to :json
  private

  def respond_with(resource, _opts = {})
    if request.method == "POST" && resource.persisted?
      # Send confirmation email with error handling
      # Only send if SMTP is configured
      if ENV['SMTP_USERNAME'].present? && ENV['SMTP_PASSWORD'].present?
        begin
          unless resource.confirmed?
            # Generate token and send email
            resource.send_confirmation_instructions
          end
        rescue => e
          # Log the error but don't fail the signup
          Rails.logger.error "Failed to send confirmation email: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          # Auto-confirm user if email sending fails (so they can still use the app)
          begin
            resource.confirm unless resource.confirmed?
          rescue => confirm_error
            Rails.logger.error "Failed to auto-confirm user: #{confirm_error.message}"
            # Continue anyway - user is still created
          end
        end
      else
        Rails.logger.warn "SMTP not configured - auto-confirming user #{resource.id}"
        # Auto-confirm user if SMTP is not configured
        begin
          resource.confirm unless resource.confirmed?
        rescue => e
          Rails.logger.error "Failed to auto-confirm user: #{e.message}"
          # Continue anyway - user is still created
        end
      end
      
      # Don't generate JWT token yet - user needs to confirm email first
      begin
        render json: {
          status: {code: 200, message: "Signed up successfully. Please check your email to confirm your account."},
          data: UserSerializer.new(resource).serializable_hash[:data][:attributes],
          email_confirmed: resource.confirmed?
        }, status: :ok
      rescue => e
        Rails.logger.error "Error serializing user response: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        # Fallback response if serialization fails
        render json: {
          status: {code: 200, message: "Signed up successfully. Please check your email to confirm your account."},
          data: {
            id: resource.id,
            username: resource.username,
            email: resource.email,
            email_confirmed: resource.confirmed?
          },
          email_confirmed: resource.confirmed?
        }, status: :ok
      end
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

