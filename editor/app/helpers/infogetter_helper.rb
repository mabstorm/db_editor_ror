module InfogetterHelper

  def get_api_key
    'AIzaSyCo_HQMkFnLnXmxmFTQTmQTNTesm5Qomz8'
  end

  def query_string(word)
    "https://www.googleapis.com/freebase/v1/text/en/#{word}?&key=#{get_api_key}"
  end

  def query(word)
    begin
      JSON.parse(HTTPClient.get_content(query_string(word.downcase.gsub(/\s/,'_'))))["result"]
    rescue
      nil # no proper result found
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
