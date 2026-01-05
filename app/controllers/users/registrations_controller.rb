class Users::RegistrationsController < Devise::RegistrationsController
  include RackSessionFix
  skip_before_action :authenticate_user!
  respond_to :json
  
  # Normal signup - no email confirmation
  def create
    build_resource(sign_up_params)
    resource.save
    yield resource if block_given?
    if resource.persisted?
      # Auto-confirm user immediately (email confirmation disabled)
      resource.update_column(:confirmed_at, Time.current) if resource.confirmed_at.nil?
      respond_with resource
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end
  
  private

  def respond_with(resource, _opts = {})
    if request.method == "POST" && resource.persisted?
      # Email confirmation disabled - users are auto-confirmed on signup
      # Generate JWT token immediately so user can log in
      begin
        render json: {
          status: {code: 200, message: "Signed up successfully! You can now log in."},
          data: UserSerializer.new(resource).serializable_hash[:data][:attributes]
        }, status: :ok
      rescue => e
        Rails.logger.error "Error serializing user response: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        # Fallback response if serialization fails
        render json: {
          status: {code: 200, message: "Signed up successfully! You can now log in."},
          data: {
            id: resource.id,
            username: resource.username,
            email: resource.email
          }
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

