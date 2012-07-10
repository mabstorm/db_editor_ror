#!/usr/bin/ruby

# File meant to update the working_wordnet.db
module WnQueriesHelper

  $db = SQLite3::Database.new("db/working_wordnet.db")


  def WnQueriesHelper.get_synsetids(word)
    $db.query("
                 SELECT synsets.synsetid
                   FROM synsets, 
                        senses, 
                        words
                  WHERE synsets.synsetid == senses.synsetid 
                        AND
                        senses.wordid == words.wordid 
                        AND
                        words.lemma LIKE ?
              ", word).to_a.flatten
  end

  def WnQueriesHelper.get_members(synsetid)
    members_and_keys = Hash.new
    $db.query("
      SELECT words.lemma, senses.sensekey
        FROM synsets, 
             senses, 
             words
       WHERE synsets.synsetid==?
             AND
             synsets.synsetid == senses.synsetid 
             AND
             senses.wordid == words.wordid
             ", synsetid).to_a.each.each {|member, key| members_and_keys[member] = key}
  end

  def WnQueriesHelper.get_definition(synsetid)
    $db.query("
      SELECT synsets.definition
      FROM   synsets
      WHERE  synsetid==?
      ", synsetid).to_a.flatten.first
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

