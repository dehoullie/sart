class PagesController < ApplicationController
  # skip_before_action :authenticate_user!, only: [ :home ]

    if defined?(authenticate_user!)
      skip_before_action :authenticate_user!, only: [:home]
    end

  def home
  end
end
