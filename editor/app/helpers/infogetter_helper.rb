module InfogetterHelper

  def get_api_key
    'AIzaSyCo_HQMkFnLnXmxmFTQTmQTNTesm5Qomz8'
  end

  def query_string(word)
    "https://www.googleapis.com/freebase/v1/text/en/#{word}?&key=#{get_api_key}"
  end

  def query(word)
    begin
      JSON.parse(HTTPClient.get_content(query_string(word)))["result"]
    rescue
      nil # no proper result found
    end
  end

  def update_freebase_session
    session[:results] = ''
    session[:this_query] = ''
    if params[:freebase]
      if params[:freebase][:query] && params[:freebase][:query]!=""
      session[:this_query] = params[:freebase][:query]
      session[:results] = query(session[:this_query].downcase.gsub(/\s/,'_'))
      end
    end
  end

end
