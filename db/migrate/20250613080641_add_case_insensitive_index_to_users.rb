class AddCaseInsensitiveIndexToUsers < ActiveRecord::Migration[7.1]
  def change
    remove_index :users, :username if index_exists?(:users, :username)

    execute <<-SQL
      CREATE UNIQUE INDEX index_users_on_lower_username
      ON users (LOWER(username));
    SQL
  end
end
