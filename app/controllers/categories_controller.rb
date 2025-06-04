class CategoriesController < ApplicationController
  def index
    @categories = Category.all # Or your specific logic to fetch categories
  end
end

