class MoviesController < ApplicationController

  def movie_params
    params.require(:movie).permit(:title, :rating, :description, :release_date)
  end

  def show
    id = params[:id] # retrieve movie ID from URI route
    @movie = Movie.find(id) # look up movie by unique ID
    # will render app/views/movies/show.<extension> by default
  end

  def index
    sort = params[:sort] || session[:sort]
    case sort
    when 'title'
      ordering,@title_header = {:title => :asc}, 'hilite'
    when 'release_date'
      ordering,@date_header = {:release_date => :asc}, 'hilite'
    end
    @all_ratings = Movie.all_ratings
    @selected_ratings = params[:ratings] || session[:ratings] || {}

    if @selected_ratings == {}
      @selected_ratings = Hash[@all_ratings.map {|rating| [rating, rating]}]
    end

    if params[:sort] != session[:sort] or params[:ratings] != session[:ratings]
      session[:sort] = sort
      session[:ratings] = @selected_ratings
      redirect_to :sort => sort, :ratings => @selected_ratings and return
    end
    @movies = Movie.where(rating: @selected_ratings.keys).order(ordering)
  end

  def new
    # default: render 'new' template
  end

  def create
    @movie = Movie.create!(movie_params)
    flash[:notice] = "#{@movie.title} was successfully created."
    redirect_to movies_path
  end

  def edit
    @movie = Movie.find params[:id]
  end

  def update
    @movie = Movie.find params[:id]
    @movie.update_attributes!(movie_params)
    flash[:notice] = "#{@movie.title} was successfully updated."
    redirect_to movie_path(@movie)
  end

  def destroy
    @movie = Movie.find(params[:id])
    @movie.destroy
    flash[:notice] = "Movie '#{@movie.title}' deleted."
    redirect_to movies_path
  end

  def search_tmdb
    @movies = Movie.find_in_tmdb(params[:search_terms])
    @mpaa_ratings = {}
    if @movies.nil?
      flash[:notice] = "'#{params[:search_terms]}' was not found in TMDb."
      redirect_to movies_path
    else
      iterate_movies
      render 'search_tmdb' # Render the 'search_tmdb' template
    end
  end

  def iterate_movies
    @movies.each do |movie|
      @mpaa_ratings[movie[:id]] = Movie.rating_of_movie(movie[:id])
    end
  end

  # def get_mpaa_rating(movie_id)
  #   # Use the code mentioned earlier to retrieve MPAA rating for a movie
  #   release_dates = Tmdb::Movie.releases(movie_id)
  #   us_release = release_dates['countries'].find { |result| result['iso_3166_1'] == 'US' && result['certification'] != "" }
  #   us_release["certification"] if us_release
  # end

  def add_tmdb
    if params[:movies].nil?
      flash[:notice] = "No movies were selected"
      redirect_to movies_path and return
    end
    params[:movies].keys.each do|id|
      Movie::add_tmdb_movie(id)
    end
    flash[:notice] = "Movies were successfully added to Rotten Potatoes"
    redirect_to movies_path and return
  end
end
