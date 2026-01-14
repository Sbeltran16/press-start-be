module Api
  class NewsController < ApplicationController
    skip_before_action :authenticate_user!

    # GET /api/news
    def index
      limit = params[:limit] ? params[:limit].to_i : 20
      page = params[:page] ? params[:page].to_i : 1
      
      # Fetch more news than needed for pagination
      all_news = IgdbService.fetch_news(limit: 100) # Fetch up to 100 articles
      
      # If no page parameter, return simple array for backward compatibility
      unless params[:page]
        render json: all_news.first(limit), status: :ok
        return
      end
      
      # Calculate pagination
      per_page = limit
      total_pages = (all_news.length.to_f / per_page).ceil
      offset = (page - 1) * per_page
      paginated_news = all_news[offset, per_page] || []
      
      render json: {
        articles: paginated_news,
        pagination: {
          current_page: page,
          per_page: per_page,
          total_articles: all_news.length,
          total_pages: total_pages,
          has_next_page: page < total_pages,
          has_prev_page: page > 1
        }
      }, status: :ok
    end
  end
end
