class Api::GameListItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_game_list

  def create
    igdb_game_id = params[:igdb_game_id]
    return render json: { error: "Missing igdb_game_id" }, status: :bad_request if igdb_game_id.blank?

    # Check if user owns the list
    if @game_list.user_id != current_user.id
      return render json: { error: "Unauthorized" }, status: :unauthorized
    end

    # Convert to integer to ensure type matching
    igdb_game_id = igdb_game_id.to_i

    # Get the next position
    max_position = @game_list.game_list_items.maximum(:position) || -1
    position = max_position + 1

    item = @game_list.game_list_items.build(igdb_game_id: igdb_game_id, position: position)

    if item.save
      render json: {
        data: {
          id: item.id,
          igdb_game_id: item.igdb_game_id,
          position: item.position
        }
      }, status: :created
    else
      render json: { errors: item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    igdb_game_id = params[:igdb_game_id]
    return render json: { error: "Missing igdb_game_id" }, status: :bad_request if igdb_game_id.blank?

    # Check if user owns the list
    if @game_list.user_id != current_user.id
      return render json: { error: "Unauthorized" }, status: :unauthorized
    end

    # Convert to integer to ensure type matching
    igdb_game_id = igdb_game_id.to_i
    
    # Debug: Log what we're looking for
    Rails.logger.info "Looking for game_list_item: game_list_id=#{@game_list.id}, igdb_game_id=#{igdb_game_id} (#{igdb_game_id.class})"
    
    # Debug: Log all items in this list (query directly to avoid association scopes)
    all_items = GameListItem.where(game_list_id: @game_list.id).pluck(:id, :igdb_game_id)
    Rails.logger.info "All items in list #{@game_list.id}: #{all_items.inspect}"
    
    # Query directly on the table to avoid any association scope issues
    item = GameListItem.find_by(game_list_id: @game_list.id, igdb_game_id: igdb_game_id)

    if item
      item.destroy
      # Reorder remaining items
      @game_list.game_list_items.order(:position).each_with_index do |item, index|
        item.update_column(:position, index)
      end
      render json: { success: true }, status: :ok
    else
      Rails.logger.warn "GameListItem not found: game_list_id=#{@game_list.id}, igdb_game_id=#{igdb_game_id}"
      render json: { error: "Game not found in list" }, status: :not_found
    end
  end

  private

  def set_game_list
    @game_list = GameList.find(params[:game_list_id])
  end
end

