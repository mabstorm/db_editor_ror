class MoviesController < ApplicationController

  def show
    id = params[:id] # retrieve movie ID from URI route
    @movie = Movie.find(id) # look up movie by unique ID
    # will render app/views/movies/show.<extension> by default
  end

  def index
    if params.has_key?(:ratings)
      @current_ratings = params[:ratings]
    elsif session.has_key?(:ratings)
      @current_ratings = session[:ratings]
    else
      @current_ratings = Hash.new
    end
    if params.has_key?(:sort_by)
      @sort_by = params[:sort_by]
    elsif session.has_key?(:sort_by)
      @sort_by = session[:sort_by]
    else
      @sort_by = ""
    end
    @movies = Movie.where(:rating => @current_ratings.keys).order(@sort_by)
    @all_ratings = ratings
    session[:sort_by] = @sort_by
    session[:ratings] = @current_ratings
  end

  def new
    # default: render 'new' template
  end

  def create
    @movie = Movie.create!(params[:movie])
    flash[:notice] = "#{@movie.title} was successfully created."
    redirect_to movies_path
  end

  def edit
    @movie = Movie.find params[:id]
  end

  def update
    @movie = Movie.find params[:id]
    @movie.update_attributes!(params[:movie])
    flash[:notice] = "#{@movie.title} was successfully updated."
    redirect_to movie_path(@movie)
  end

  def destroy
    @movie = Movie.find(params[:id])
    @movie.destroy
    flash[:notice] = "Movie '#{@movie.title}' deleted."
    redirect_to movies_path
  end

  def ratings
    Movie::RATINGS
  end


end
