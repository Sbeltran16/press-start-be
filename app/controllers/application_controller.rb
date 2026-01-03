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
    
    if !current_user.confirmed?
      render json: { 
        error: "Please confirm your email address to continue",
        email_confirmed: false,
        email: current_user.email
      }, status: :forbidden
    end
  end
end
