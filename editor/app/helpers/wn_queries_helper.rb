#!/usr/bin/ruby

# File meant to update the working_wordnet.db
module WnQueriesHelper

  if $0 == "irb" # assume we enter irb for testing from the main folder
    $sid = '102512053' 
    $db = SQLite3::Database.new("../../db/wordnet_3.1+.db")
  else
    $db = SQLite3::Database.new("db/wordnet_3.1+.db")
  end

  include ApplyEditHelper

  $synsetidposquery = $db.prepare("
                 SELECT synsets.synsetid, synsets.pos
                   FROM synsets, 
                        senses, 
                        words
                  WHERE synsets.synsetid == senses.synsetid 
                        AND
                        senses.wordid == words.wordid 
                        AND
                        (words.lemma == ?
                                          OR
                         words.lemma LIKE ?
                                          OR
                         words.lemma LIKE ?)
                   ")
  $synsetidposquerywithpos = $db.prepare("
                 SELECT synsets.synsetid, synsets.pos
                   FROM synsets, 
                        senses, 
                        words
                  WHERE synsets.synsetid == senses.synsetid 
                        AND
                        senses.wordid == words.wordid 
                        AND
                        synsets.pos == ?
                        AND
                        (words.lemma == ?
                                          OR
                         words.lemma LIKE ?
                                          OR
                         words.lemma LIKE ?)
                   ")
  $synsetidposqueryexact = $db.prepare("
                 SELECT synsets.synsetid, synsets.pos
                   FROM synsets, 
                        senses, 
                        words
                  WHERE synsets.synsetid == senses.synsetid 
                        AND
                        senses.wordid == words.wordid 
                        AND
                        words.lemma == ?
  
                   ")
  $synsetidposquerywithposexact = $db.prepare("
                 SELECT synsets.synsetid, synsets.pos
                   FROM synsets, 
                        senses, 
                        words
                  WHERE synsets.synsetid == senses.synsetid 
                        AND
                        senses.wordid == words.wordid 
                        AND
                        synsets.pos == ?
                        AND
                        words.lemma == ?

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
      select link,
             synset2id
        from semlinks, 
             linktypes
       where semlinks.linkid == linktypes.linkid
             and
             synset1id == ?
      ")
  # senseid to senseid
  $lexlinksquery = $db.prepare("
      select senseid1,
             linkid,
             senseid2
        from lexlinks, 
             senses
       where senses.synsetid == ?    
             and
             lexlinks.senseid1==senses.senseid
             or
             senses.synsetid == ?
             and
             lexlinks.senseid2==senses.senseid
      ")

  $sensekeyfromsenseid = $db.prepare("
      select sensekey
        from senses
       where senseid == ?
      ")


  $posquery = $db.prepare("
      SELECT synsets.pos
        FROM synsets
       WHERE synsetid==?
      ")

  $distinctsemlinksquery = $db.prepare("
     SELECT DISTINCT  link
                FROM  linktypes
                WHERE linktype=='sem'
                OR    linktype=='both'
     ")
  $distinctlexlinksquery = $db.prepare("
     SELECT DISTINCT link
                FROM linktypes
                WHERE linktype=='lex'
                OR    linktype=='both'
   ")
  $posmaplinksquery = $db.prepare("
     SELECT * FROM postypes
     ")
  $linkstablequery = $db.prepare("
     SELECT linkid, link FROM linktypes
     ")

  $sensekeytosynsetid = $db.prepare("
     SELECT synsetid FROM senses WHERE sensekey==?
     ")
  $senseidtosensekey = $db.prepare("
     SELECT sensekey FROM senses WHERE senseid==?
     ")
  $sensekeytosenseid = $db.prepare("
     SELECT senseid FROM senses WHERE sensekey==?
     ")
  $sensekeytowordid = $db.prepare("
     SELECT wordid FROM senses WHERE sensekey==?
     ")

  $get_lexdomainid_query = $db.prepare("
    SELECT lexdomainid
      FROM synsets
     WHERE synsetid==?
    ")

  # GLOBAL CONSTANTS DERIVED FROM WORDNET
  $all_semlinks = $distinctsemlinksquery.execute.to_a.flatten
  $all_lexlinks = $distinctlexlinksquery.execute.to_a.flatten
  $pos_map = $posmaplinksquery.execute.to_a.each.map {|initial, fullword| initial}
  $full_pos_map = $posmaplinksquery.execute.to_a.inject({}) {|h,(k,v)| h[v]=k; h}
  $links_map = $linkstablequery.execute.to_a.inject({}) {|h,(k,v)| h[k]=v; h}
  $reverse_links_map = $links_map.invert

  def WnQueriesHelper.get_synsetids_and_pos(word, pos, exact)
    return [] if word.empty?
    sids_and_pos = Hash.new
    if exact=="1"
      if (pos.nil? || pos.empty?)
        $synsetidposqueryexact.execute(word).to_a.each.each{|sid, pos| sids_and_pos[sid] = pos}
      else
        $synsetidposquerywithposexact.execute(pos, word).to_a.each.each{|sid, pos| sids_and_pos[sid] = pos}
      end
    else
      if (pos.nil? || pos.empty?)
        $synsetidposquery.execute(word,"% #{word}","#{word} %").to_a.each.each{|sid, pos| sids_and_pos[sid] = pos}
      else
        $synsetidposquerywithpos.execute(pos, word,"% #{word}","#{word} %").to_a.each.each{|sid, pos| sids_and_pos[sid] = pos}
      end
    end
    return sids_and_pos
  end

  def WnQueriesHelper.get_pos(synsetid)
    return "n" if synsetid==0
    $posquery.execute(synsetid).to_a.flatten.first
  end

  def WnQueriesHelper.get_synsetids(word)
    return [] if word.empty?
    get_synsetids_and_pos(word, nil, 0).keys
  end

  def WnQueriesHelper.get_members(synsetid)
    members_and_keys = Hash.new
    return members_and_keys if synsetid==0
    $membersquery.execute(synsetid).to_a.each.each {|member, key| members_and_keys[member] = key}
    return members_and_keys
  end

  def WnQueriesHelper.get_definition(synsetid)
    return "" if synsetid==0
    $definitionquery.execute(synsetid).to_a.flatten.first
  end
  
  def WnQueriesHelper.get_semlinks(synsetid)
    return [] if synsetid==0
    $semlinksquery.execute(synsetid).to_a
  end
  def WnQueriesHelper.get_lexlinks(synsetid)
    return [] if synsetid==0
    $lexlinksquery.execute(synsetid,synsetid).to_a.each.map {|k1,linkid,k2| [k1,$links_map[linkid],k2]}
  end
  def WnQueriesHelper.get_lexdomainid(synsetid)
    return 99 if synsetid==0
    $get_lexdomainid_query.execute(synsetid).to_a.first.first rescue 99
  end
  def WnQueriesHelper.get_lexlinkskeys(synsetid)
    return [] if synsetid==0
    get_lexlinks(synsetid).map {|k1,link,k2| [senseid_to_sensekey(k1),link,senseid_to_sensekey(k2)] }
  end

  def WnQueriesHelper.get_synsetid_from_sensekey(sensekey)
    $sensekeytosynsetid.execute(sensekey).to_a.flatten.first
  end
  def WnQueriesHelper.get_wordid_from_sensekey(sensekey)
    $sensekeytowordid.execute(sensekey).to_a.flatten.first
  end
  def WnQueriesHelper.senseid_to_sensekey(senseid)
    $senseidtosensekey.execute(senseid).to_a.flatten.first
  end
  def WnQueriesHelper.sensekey_to_senseid(sensekey)
    $sensekeytosenseid.execute(sensekey).to_a.flatten.first
  end 
  def render_members_and_keys(mak)
    return if mak.nil?
#    content = File.read('app/views/wn_queries/member_key.html.haml')
#    Haml::Engine.new(content).render(:locals => {:members_and_keys=>mak})
    render :file => 'app/views/wn_queries/member_key', :locals => {:members_and_keys => mak }, :handlers => [:haml]
  end

  def WnQueriesHelper.apply_edit_to_database(edit)
    ApplyEditHelper.update_synset(edit)
    ApplyEditHelper.update_senses(edit)
    ApplyEditHelper.update_semlinks(edit)

  end


end

class SynsetInfo
  attr_reader :synsets, :word, :pos
  def initialize(word, pos, exact)
    raise ArgumentError, "nil word" if word.nil?
    pos = $full_pos_map[pos] unless $full_pos_map[pos].nil? # convert 'verb' to 'v', etc.
    @pos = pos
    @word = word
    @synsets = Array.new
    WnQueriesHelper.get_synsetids_and_pos(word, @pos, exact).each {|synsetid,pos| @synsets.push(Synset.new(synsetid,pos))}

    # try using the 'word' as a synsetid instead if no results came up
    if (@synsets.empty? && !word.empty?)
      synsetid_synset = Synset.new(word)
      @synsets.push(synsetid_synset) unless (synsetid_synset.definition.nil? && synsetid_synset.members_and_keys.empty?)
    end
    # try using the 'word' as a sensekey
    if (@synsets.empty? && !word.empty?)
      sensekey_synset = Synset.new(WnQueriesHelper.get_synsetid_from_sensekey(word))
      @synsets.push(sensekey_synset) unless (sensekey_synset.definition.nil? && sensekey_synset.members_and_keys.empty?)
    end
  end
end

class Synset
  attr_accessor :synsetid, :pos, :members_and_keys, :definition, :semlinks, :lexlinks, :lexdomainid, :example
  def initialize(synsetid, pos=nil)
    raise ArgumentError, "nil synsetid" if synsetid.nil?
    @synsetid = synsetid
    @example = ''
    pos = WnQueriesHelper.get_pos(synsetid) if pos.nil?
    @pos = pos
    @members_and_keys = WnQueriesHelper.get_members(synsetid)
    @definition = WnQueriesHelper.get_definition(synsetid)
  end
  def set_semlinks
    @semlinks = WnQueriesHelper.get_semlinks(synsetid)
  end
  def set_lexlinks
    @lexlinks = WnQueriesHelper.get_lexlinkskeys(synsetid)
  end
  def set_lexdomainid
    @lexdomainid = WnQueriesHelper.get_lexdomainid(synsetid)
  end
end

def wordnet_query_session
  session[:wordnetquery] = params[:wordnet][:query] rescue nil
  session[:wordnetquerypos] = params[:wordnet][:pos] rescue nil
  session[:chosen_synsetid] = params[:synsetid] rescue nil
  session[:wordnetqueryexact] = params[:wordnet][:exact_match] rescue nil
end

def wordnet_query(wnquery, synsetid, wnpos, exact)
  wnresults = SynsetInfo.new(wnquery, wnpos, exact) rescue nil
  chosen_synset = Synset.new(synsetid) rescue nil
  return chosen_synset, wnresults
end


