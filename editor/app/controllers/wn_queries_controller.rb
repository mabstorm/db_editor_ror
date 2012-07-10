class WnQueriesController < ApplicationController
  def query
    @wnresults = SynsetInfo.new(params[:wordnet][:query]) rescue nil
    @chosen_synset = Synset.new(params[:synsetid]) rescue nil
  end
end
