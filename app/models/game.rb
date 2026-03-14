# frozen_string_literal: true

class Game < ApplicationRecord
  validates :igdb_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :data, presence: true

  # Returns the game as an IGDB-shaped hash for API responses (id, name, cover, etc.)
  def to_igdb_response
    data.is_a?(Hash) ? data.merge("id" => igdb_id, "name" => name) : {}
  end
end
