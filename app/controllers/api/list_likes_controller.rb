module Api
  class ListLikesController < ApplicationController
    before_action :authenticate_user!

    def create
      game_list = GameList.find(params[:game_list_id])
      
      like = game_list.list_likes.find_or_initialize_by(user_id: current_user.id)
      
      if like.persisted? || like.save
        render json: { liked: true, likes_count: game_list.list_likes.count }, status: :ok
      else
        render json: { errors: like.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      game_list = GameList.find(params[:game_list_id])
      like = game_list.list_likes.find_by(user_id: current_user.id)
      like&.destroy

      render json: { liked: false, likes_count: game_list.list_likes.count }, status: :ok
    end
  end
end
