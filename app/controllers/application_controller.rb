class ApplicationController < ActionController::API
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!
  before_action :check_email_confirmation

  protected
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: extra_params)
    devise_parameter_sanitizer.permit(:account_update, keys: extra_params)
  end

  def extra_params
    %i[username email password]
  end

  def check_email_confirmation
    # Skip check for certain actions
    return if devise_controller? && ['create', 'confirm', 'resend'].include?(action_name)
    return if controller_name == 'email_confirmations'
    return unless current_user # Only check if user is authenticated
    
    # Allow unconfirmed users to access their accounts (for existing users who signed up before email was configured)
    # They can still use the app, but email confirmation is recommended
    if !current_user.confirmed?
      Rails.logger.info "User #{current_user.id} (#{current_user.email}) accessing account without email confirmation"
      # Don't block - allow them to use the app
      # The frontend can show a banner prompting them to confirm their email
    end
  end
end
