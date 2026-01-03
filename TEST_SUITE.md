# Test Suite Documentation

This document describes the comprehensive unit test suite created for the Press Start backend.

## Test Coverage

### Models

#### User Model (`test/models/user_test.rb`)
- ✅ Validations (email, username, bio length)
- ✅ Uniqueness constraints (case-insensitive username)
- ✅ Email confirmation functionality
- ✅ Associations (game_lists, reviews, followers, following)
- ✅ Dependent destroy behavior

#### GameList Model (`test/models/game_list_test.rb`)
- ✅ Validations (user, name)
- ✅ Associations (user, game_list_items, list_likes)
- ✅ Custom methods (games_count, first_game_id, likes_count, liked_by?)
- ✅ Dependent destroy behavior

#### Review Model (`test/models/review_test.rb`)
- ✅ Validations (user, igdb_game_id, rating)
- ✅ Rating range validation (1-5)
- ✅ Associations (user, review_likes, review_comments)
- ✅ Dependent destroy behavior

### Controllers

#### Registration Controller (`test/controllers/users/registrations_controller_test.rb`)
- ✅ User creation with valid params
- ✅ Validation errors (invalid email, duplicate email/username, short password)
- ✅ Auto-confirmation when SMTP is not configured
- ✅ Response format and data structure

#### Sessions Controller (`test/controllers/users/sessions_controller_test.rb`)
- ✅ Login rejection for unconfirmed users
- ✅ Successful login for confirmed users
- ✅ Invalid credentials handling
- ✅ JWT token generation

#### Email Confirmations Controller (`test/controllers/api/email_confirmations_controller_test.rb`)
- ✅ Email confirmation with valid token
- ✅ Error handling (invalid token, missing token)
- ✅ Already confirmed email handling
- ✅ JWT token return after confirmation
- ✅ Resend confirmation email functionality

#### Game Lists Controller (`test/controllers/api/game_lists_controller_test.rb`)
- ✅ Create game list (authenticated)
- ✅ Authentication requirements
- ✅ Get user's lists
- ✅ Get specific list (public access)
- ✅ Update and destroy lists
- ✅ Popular lists endpoint (public access)

## Running Tests

### Prerequisites
1. Ensure test database is set up:
   ```bash
   rails db:test:prepare
   ```

2. Make sure all dependencies are installed:
   ```bash
   bundle install
   ```

### Run All Tests
```bash
rails test
```

### Run Specific Test Files
```bash
# Run all model tests
rails test test/models

# Run all controller tests
rails test test/controllers

# Run specific test file
rails test test/models/user_test.rb

# Run specific test
rails test test/models/user_test.rb:10
```

### Run Tests with Verbose Output
```bash
rails test --verbose
```

### Run Tests in Parallel (default)
Tests run in parallel by default. To disable:
```bash
PARALLEL_WORKERS=0 rails test
```

## Test Structure

### Model Tests
Model tests verify:
- Validations
- Associations
- Custom methods
- Business logic
- Dependent destroy behavior

### Controller Tests
Controller tests verify:
- HTTP status codes
- Response formats
- Authentication/authorization
- Error handling
- Data persistence

## Test Fixtures

Fixtures are located in `test/fixtures/`. Currently includes:
- `users.yml` - User fixtures
- `reviews.yml` - Review fixtures
- `game_likes.yml` - Game like fixtures
- And more...

## Test Environment

The test environment is configured in `config/environments/test.rb`:
- Uses test database
- Disables caching
- Uses test mailer (emails stored in `ActionMailer::Base.deliveries`)
- Shows full error reports

## Continuous Integration

These tests should be run:
- Before committing code
- In CI/CD pipeline
- Before deploying to production

## Adding New Tests

When adding new features:
1. Create corresponding test file in appropriate directory
2. Follow existing test patterns
3. Test both success and failure cases
4. Test edge cases and boundary conditions
5. Ensure tests are independent and can run in any order

## Example Test Structure

```ruby
require "test_helper"

class MyModelTest < ActiveSupport::TestCase
  def setup
    # Setup test data
  end

  test "should be valid with valid attributes" do
    # Test valid case
  end

  test "should require required field" do
    # Test validation
  end
end
```

## Notes

- Tests use transactional fixtures (each test runs in a transaction that's rolled back)
- Tests run in parallel by default for speed
- Use `assert` for positive assertions, `assert_not` for negative
- Use `assert_difference` and `assert_no_difference` for counting changes
- Use `assert_response` for HTTP status codes in controller tests

