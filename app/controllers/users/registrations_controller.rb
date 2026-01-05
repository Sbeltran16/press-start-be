class Users::RegistrationsController < Devise::RegistrationsController
  include RackSessionFix
  skip_before_action :authenticate_user!
  skip_before_action :check_email_confirmation
  respond_to :json
  
  # Override create to prevent Devise from automatically sending confirmation emails
  def create
    build_resource(sign_up_params)
    
    # Skip Devise's automatic confirmation email sending
    # We'll send it manually in respond_with
    resource.skip_confirmation_notification!
    
    resource.save
    yield resource if block_given?
    if resource.persisted?
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
      # Send confirmation email with error handling
      # Only send if SMTP is fully configured
      smtp_username = ENV['SMTP_USERNAME'].to_s.strip
      smtp_password = ENV['SMTP_PASSWORD'].to_s.strip
      smtp_address = ENV['SMTP_ADDRESS'].to_s.strip
      
      smtp_configured = smtp_username.present? && smtp_password.present? && smtp_address.present?
      
      Rails.logger.info "User signup for #{resource.email}: SMTP configured=#{smtp_configured}"
      
      if smtp_configured
        begin
          unless resource.confirmed?
            # Generate token and send email
            Rails.logger.info "Attempting to send confirmation email to #{resource.email}"
            email_sent = resource.send_confirmation_instructions
            
            if email_sent
              Rails.logger.info "✅ Confirmation email sent successfully to #{resource.email}"
            else
              Rails.logger.error "❌ Failed to send confirmation email to #{resource.email}"
              Rails.logger.warn "Auto-confirming user #{resource.id} (#{resource.email}) since email sending failed"
              # Auto-confirm if email sending fails so user can still use the app
              resource.update_column(:confirmed_at, Time.current) unless resource.confirmed?
            end
          end
        rescue => e
          # Log the error but don't fail the signup
          Rails.logger.error "❌ Exception while sending confirmation email to #{resource.email}: #{e.class} - #{e.message}"
          Rails.logger.error "Backtrace: #{e.backtrace.first(10).join("\n")}"
          Rails.logger.warn "Auto-confirming user #{resource.id} (#{resource.email}) due to email sending exception"
          # Auto-confirm on exception so user can still use the app
          resource.update_column(:confirmed_at, Time.current) unless resource.confirmed?
        end
      else
        missing = []
        missing << "SMTP_USERNAME" unless smtp_username.present?
        missing << "SMTP_PASSWORD" unless smtp_password.present?
        missing << "SMTP_ADDRESS" unless smtp_address.present?
        Rails.logger.warn "SMTP not fully configured (missing: #{missing.join(', ')}) - auto-confirming user"
        Rails.logger.warn "User #{resource.id} (#{resource.email}) will be auto-confirmed since email is not configured"
        # Auto-confirm if SMTP is not configured so users can still use the app
        resource.update_column(:confirmed_at, Time.current) unless resource.confirmed?
      end
      
      # Generate appropriate message based on email confirmation status
      if resource.confirmed?
        message = "Signed up successfully! You can now log in."
      elsif smtp_configured
        message = "Signed up successfully. Please check your email (#{resource.email}) to confirm your account."
      else
        message = "Signed up successfully. Email confirmation is not configured. Please contact support."
      end
      
      # Don't generate JWT token yet - user needs to confirm email first (unless auto-confirmed)
      begin
        render json: {
          status: {code: 200, message: message},
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

