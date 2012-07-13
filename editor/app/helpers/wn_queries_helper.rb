#!/usr/bin/ruby

# File meant to update the working_wordnet.db
module WnQueriesHelper

  if $0 == "irb"
    $sid = '102512053'
    $db = SQLite3::Database.new("../../db/working_wordnet.db")
  else
    $db = SQLite3::Database.new("db/working_wordnet.db")
  end

  $synsetidposquery = $db.prepare("
                 SELECT synsets.synsetid, synsets.pos
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
        FROM synsets
       WHERE synsetid==?
      ")

  $semlinksquery = $db.prepare("
      SELECT link,
             synset2id
        FROM semlinks, 
             linktypes
       WHERE semlinks.linkid == linktypes.linkid
             AND
             synset1id == ?
      ")

  $posquery = $db.prepare("
     SELECT synsets.pos
     FROM synsets
     WHERE synsetid==?
     ")

  $distinctlinksquery = $db.prepare("
     SELECT DISTINCT link
                FROM linktypes
     ")
  $all_links = $distinctlinksquery.execute.to_a.flatten

  def WnQueriesHelper.get_synsetids_and_pos(word)
    sids_and_pos = Hash.new
    $synsetidposquery.execute(word).to_a.each.each{|sid, pos| sids_and_pos[sid] = pos}
    return sids_and_pos
  end

  def WnQueriesHelper.get_pos(synsetid)
    $posquery.execute(synsetid).to_a.flatten.first
  end

  def WnQueriesHelper.get_synsetids(word)
    get_synsetids_and_pos(word).keys
  end

  def WnQueriesHelper.get_members(synsetid)
    members_and_keys = Hash.new
    $membersquery.execute(synsetid).to_a.each.each {|member, key| members_and_keys[member] = key}
    return members_and_keys
  end

  def WnQueriesHelper.get_definition(synsetid)
    $definitionquery.execute(synsetid).to_a.flatten.first
  end
  
  def WnQueriesHelper.get_semlinks(synsetid)
    $semlinksquery.execute(synsetid).to_a
  end
  
  def render_members_and_keys(mak)
    return if mak.nil?
#    content = File.read('app/views/wn_queries/member_key.html.haml')
#    Haml::Engine.new(content).render(:locals => {:members_and_keys=>mak})
    render :file => 'app/views/wn_queries/member_key', :locals => {:members_and_keys => mak }, :handlers => [:haml]
  end



end

class SynsetInfo
  attr_reader :synsets, :word
  def initialize(word)
    raise ArgumentError, "nil word" if word.nil?
    @word = word
    @synsets = Array.new
    WnQueriesHelper.get_synsetids_and_pos(word).each {|synsetid,pos| @synsets.push(Synset.new(synsetid,pos))}
    # try using the 'word' as a synsetid instead if no results came up
    if @synsets.empty?
      @synsets.push(Synset.new(word, WnQueriesHelper.get_pos(word)))
    end
  end
end

class Synset
  attr_reader :synsetid, :pos, :members_and_keys, :definition, :semlinks
  def initialize(synsetid, pos=nil)
    raise ArgumentError, "nil synsetid" if synsetid.nil?
    @synsetid = synsetid
    pos = WnQueriesHelper.get_pos(synsetid) if pos.nil?
    @pos = pos
    @members_and_keys = WnQueriesHelper.get_members(synsetid)
    @definition = WnQueriesHelper.get_definition(synsetid)
  end
  def set_semlinks
    @semlinks = WnQueriesHelper.get_semlinks(synsetid)
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
