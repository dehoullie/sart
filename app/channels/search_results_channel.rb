class SearchResultsChannel < ApplicationCable::Channel
  def subscribed
    query = params[:query]
    stream_from "search_results_#{query}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
