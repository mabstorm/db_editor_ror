class InfogetterController < ApplicationController
  include InfogetterHelper
  def index
    if params[:freebase]
      @query = params[:freebase][:query].downcase.gsub(/\s/,'_')
      @results = query(@query)
    end

    
  end

  def show

  end
end
