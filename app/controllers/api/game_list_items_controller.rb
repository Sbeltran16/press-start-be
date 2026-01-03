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

    item = @game_list.game_list_items.find_by(igdb_game_id: igdb_game_id)

    if item
      item.destroy
      # Reorder remaining items
      @game_list.game_list_items.order(:position).each_with_index do |item, index|
        item.update_column(:position, index)
      end
      render json: { success: true }, status: :ok
    else
      render json: { error: "Game not found in list" }, status: :not_found
    end
  end

  private

  def set_game_list
    @game_list = GameList.find(params[:game_list_id])
  end
end

