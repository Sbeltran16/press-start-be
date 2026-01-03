# Test configuration helper
# This file ensures test environment is properly configured

# Set test JWT secret if not already set
if Rails.application.credentials.secret_key_base.nil?
  Rails.application.credentials.secret_key_base = 'test_secret_key_for_jwt_token_generation_in_test_environment_only'
end

