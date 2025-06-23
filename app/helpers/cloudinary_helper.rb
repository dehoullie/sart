module CloudinaryHelper
  def cloudinary_poster(movie)
    "https://res.cloudinary.com/dphhzuobi/image/upload/sart/movies/#{movie.api_movie_id}_poster.jpg"
  end

  def cloudinary_backdrop(movie)
    "https://res.cloudinary.com/dphhzuobi/image/upload/sart/movies/#{movie.api_movie_id}_backdrop"
  end

  def cloudinary_cast_photo(cast)
    "https://res.cloudinary.com/dphhzuobi/image/upload/sart/cast/#{cast.api_cast_id}_profile"
  end
end
