#!/usr/bin/ruby

# File meant to update the working_wordnet.db
module WnQueriesHelper

  $db = SQLite3::Database.new("db/working_wordnet.db")
  $synsetidquery = $db.prepare("
                 SELECT synsets.synsetid
                   FROM synsets, 
                        senses, 
                        words
                  WHERE synsets.synsetid == senses.synsetid 
                        AND
                        senses.wordid == words.wordid 
                        AND
                        words.lemma LIKE ?
                   ")

  $membersquery = $db.prepare("
      SELECT words.lemma, senses.sensekey
        FROM synsets, 
             senses, 
             words
       WHERE synsets.synsetid==?
             AND
             synsets.synsetid == senses.synsetid 
             AND
             senses.wordid == words.wordid
             ")

  $definitionquery = $db.prepare("
      SELECT synsets.definition
      FROM   synsets
      WHERE  synsetid==?
      ")

  def WnQueriesHelper.get_synsetids(word)
    $synsetidquery.execute(word).to_a.flatten
  end

  def WnQueriesHelper.get_members(synsetid)
    members_and_keys = Hash.new
    $membersquery.execute(synsetid).to_a.each.each {|member, key| members_and_keys[member] = key}
  end

  def WnQueriesHelper.get_definition(synsetid)
    $definitionquery.execute(synsetid).to_a.flatten.first
  end
  
  def render_members_and_keys(mak)
    return if mak.nil?
#    content = File.read('app/views/wn_queries/member_key.html.haml')
#    Haml::Engine.new(content).render(:locals => {:members_and_keys=>mak})
    render :file => 'app/views/wn_queries/member_key.html.haml', :locals => {:members_and_keys => mak }, :handlers => [:haml]
  end



end

class SynsetInfo
  attr_reader :synsets, :word
  def initialize(word)
    raise ArgumentError, "nil word" if word.nil?
    @word = word
    @synsets = Array.new
    WnQueriesHelper.get_synsetids(word).each {|synsetid| @synsets.push(Synset.new(synsetid))}
  end
end

class Synset
  attr_reader :synsetid, :members_and_keys, :definition
  def initialize(synsetid)
    raise ArgumentError, "nil synsetid" if synsetid.nil?
    @synsetid = synsetid
    @members_and_keys = WnQueriesHelper.get_members(synsetid)
    @definition = WnQueriesHelper.get_definition(synsetid)
  end
end

def wordnet_query_session
  session[:wordnetquery] = params[:wordnet][:query] rescue nil
  session[:chosen_synsetid] = params[:synsetid] rescue nil
end

def wordnet_query(wnquery, synsetid)
  wnresults = SynsetInfo.new(wnquery) rescue nil
  chosen_synset = Synset.new(synsetid) rescue nil
  return chosen_synset, wnresults
end

=begin
def test_prepare_queries
  testlist = %w{fish water waterfall miracle get fun wonderful}
  
  begin_time = Time.now
  5.times do |t|
    results = Array.new
    testlist.each do |word|
      results.push(WnQueriesHelper.get_synsetids(word))
    end
    puts t
  end
  end_time = Time.now

  begin_time2 = Time.now
  5.times do |t|
    results = Array.new
    testlist.each do |word|
      results.push(WnQueriesHelper.old_get_synsetids(word))
    end
    puts t
  end
  end_time2 = Time.now
  puts "new: #{end_time - begin_time}\nold: #{end_time2 - begin_time2}"
end
=end
