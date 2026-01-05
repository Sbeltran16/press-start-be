class Api::EmailConfirmationsController < ApplicationController
  skip_before_action :authenticate_user!
  # Email confirmation disabled - this controller is kept for future use

  # GET /api/email_confirmations/confirm?confirmation_token=xxx
  def confirm
    token = params[:confirmation_token]
    
    if token.blank?
      render json: { error: "Confirmation token is required" }, status: :bad_request
      return
    end

    user = User.find_by(confirmation_token: token)
    
    if user.nil?
      render json: { error: "Invalid confirmation token" }, status: :not_found
      return
    end

    # Email confirmation disabled - check confirmed_at directly
    if user.confirmed_at.present?
      render json: { 
        message: "Email already confirmed",
        email_confirmed: true
      }, status: :ok
      return
    end

    if user.confirmation_sent_at && user.confirmation_sent_at < 24.hours.ago
      # Token expired, send new one
      user.send_confirmation_instructions
      render json: { 
        error: "Confirmation token expired. A new confirmation email has been sent.",
        email_confirmed: false
      }, status: :unprocessable_entity
      return
    end

    # Email confirmation disabled - manually set confirmed_at
    if user.update_column(:confirmed_at, Time.current)
      # Generate JWT token after confirmation
      token = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
      
      render json: {
        status: { code: 200, message: "Email confirmed successfully" },
        data: UserSerializer.new(user).serializable_hash[:data][:attributes],
        token: token,
        email_confirmed: true
      }, status: :ok
    else
      render json: { 
        error: "Failed to confirm email",
        errors: user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # POST /api/email_confirmations/resend
  def resend
    email = params[:email]
    
    if email.blank?
      render json: { error: "Email is required" }, status: :bad_request
      return
    end

    user = User.find_by(email: email)
    
    if user.nil?
      # Don't reveal if user exists or not for security
      render json: { 
        message: "If an account exists with this email, a confirmation email has been sent."
      }, status: :ok
      return
    end

    # Email confirmation disabled - check confirmed_at directly
    if user.confirmed_at.present?
      render json: { 
        message: "Email is already confirmed",
        email_confirmed: true
      }, status: :ok
      return
    end

    user.send_confirmation_instructions
    
    render json: { 
      message: "Confirmation email has been sent",
      email_confirmed: false
    }, status: :ok
  end
end

