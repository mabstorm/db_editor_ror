module InfogetterHelper

  def get_api_key
    'AIzaSyCo_HQMkFnLnXmxmFTQTmQTNTesm5Qomz8'
  end

  def query_string(word)
    "https://www.googleapis.com/freebase/v1/text/en/#{word}?&key=#{get_api_key}"
  end

  def query(word)
    JSON.parse(HTTPClient.get_content(query_string(word)))["result"]
  end

end
