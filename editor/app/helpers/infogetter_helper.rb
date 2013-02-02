module InfogetterHelper

  def get_api_key
    'AIzaSyCo_HQMkFnLnXmxmFTQTmQTNTesm5Qomz8'
  end

  def query_string(word)
    "https://www.googleapis.com/freebase/v1/text/en/#{word}?&key=#{get_api_key}"
  end

  def query(word)
    return if (word.empty? || word.nil?)
    begin
      JSON.parse(HTTPClient.get_content(query_string(word.downcase.gsub(/\s/,'_'))))["result"]
    rescue
      wikipedia_query(word)
    end
  end

  def wikipedia_query(word)
    # lookup the first 2 paragraphs of wikipedia using the wikipedia-client gem
    begin
      Wikipedia.find(word.downcase.gsub(/[^a-z0-9.,]/,' ')).sanitized_content.match(/(<p>.*?<\/p>.*?){2}/m)[0].html_safe
    rescue
      "No result found"
    end
  end

  def update_freebase_session
    session[:freebasequery] = ''
    if params[:freebase]
      if params[:freebase][:query] && params[:freebase][:query]!=""
        session[:freebasequery] = params[:freebase][:query]
      end
    end
  end

end
