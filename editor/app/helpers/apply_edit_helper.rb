module ApplyEditHelper
  $update_synset_query = $db.prepare("
    UPDATE synsets
       SET pos=?,
           lexdomainid=?,
           definition=?
     WHERE synsetid==?
    ")
  $insert_synset_query = $db.prepare("
    INSERT INTO synsets
    VALUES(NULL,?,?,?,?)
    ")
  $get_synsetid_from_definition = $db.prepare("SELECT synsetid FROM synsets WHERE definition==?")
  $get_lexdomainid_query = $db.prepare("
    SELECT lexdomainid
      FROM synsets
     WHERE synsetid==?
    ")
  def ApplyEditHelper.new_synsetid
    $db.query("SELECT max(synsetid) FROM senses").to_a.first.first + 1
  end


  # columns:
  # id, synsetid, pos, lexdomain, definition
  def ApplyEditHelper.update_synset(edit)
    if not edit.respond_to? :lexdomainid
      lexdomainid = $get_lexdomainid_query.execute(edit.synsetid).to_a.first.first rescue 99
    else
      lexdomainid = edit.lexdomainid
    end

    # try to find a synsetid based on the definition
    if edit.synsetid==0
      edit.synsetid = $get_synsetid_from_definition.execute(edit.definition).to_a.first.first rescue 0
    end
    if edit.synsetid==0
      $insert_synset_query.execute(ApplyEditHelper.new_synsetid, edit.pos, lexdomainid, edit.definition)
    else
      $update_synset_query.execute(edit.pos, lexdomainid, edit.definition, edit.synsetid)
    end
    # update the edits synsetid to make sure we don't add multiple times to db
    edit.update_attributes({"synsetid" => $get_synsetid_from_definition.execute(edit.definition).to_a.first.first})
  end



  $get_info_from_sense_query = $db.prepare("
    SELECT wordid,
           casedwordid,
           senseid,
           sensenum,
           lexid,
           tagcount
      FROM senses
     WHERE sensekey==?
       AND synsetid==?
    ")
  $update_sense_query = $db.prepare("
    UPDATE senses
       SET wordid=?,
           casedwordid=?,
           senseid=?,
           sensenum=?,
           lexid=?,
           tagcount=?
     WHERE sensekey==?
       AND synsetid==?
    ")
  $insert_new_sense_query = $db.prepare("
    INSERT INTO senses
    VALUES(?,?,?,?,?,?,?,?,?)
    ")
  $synsetid_from_key = $db.prepare("SELECT synsetid FROM senses WHERE sensekey==?")
  $get_word_from_id = $db.prepare("SELECT lemma FROM words WHERE wordid==?")
  $get_wordid_from_lemma = $db.prepare("SELECT wordid FROM words WHERE lemma==?")
  $get_cased_from_id = $db.prepare("SELECT cased FROM casedwords WHERE casedwordid==?")
  $get_casedwordid_from_cased = $db.prepare("SELECT casedwordid FROM casedwords WHERE cased==?")
  $insert_new_word = $db.prepare("INSERT INTO words VALUES(NULL,?)")
  $insert_new_casedword = $db.prepare("INSERT INTO casedwords VALUES(NULL,?,?)")
  $new_sensenum_query = $db.prepare("
    SELECT count(senseid)
      FROM senses, synsets
     WHERE wordid==?
       and synsets.pos==?
       and senses.synsetid==synsets.synsetid
    ")

  def ApplyEditHelper.new_sensenum(wordid,pos)
    $new_sensenum_query.execute(wordid,pos).to_a.first.first + 1 rescue 1
  end
     

  def ApplyEditHelper.different_key_already_exists?(sensekey, synsetid)
    $synsetid_from_key.execute(sensekey).to_a.first.first!=synsetid rescue false
  end


  # columns:
  # wordid, casedwordid, synsetid, sensenum, lexid, tagcount, sensekey, new_sensekey
  def ApplyEditHelper.update_senses(edit)

    # Dealing with synsetid
    synsetid = edit.synsetid
    if (synsetid.nil? || synsetid==0)
      synsetid = $get_synsetid_from_definition.execute(edit.definition).to_a.first.first rescue nil
    end
    return if synsetid.nil?

    # Update database for every sense of every word in `members`
    edit.members.each_pair do |cased, key|
      word = cased.downcase
      old_wordid, old_casedwordid, old_senseid, old_sensenum, old_lexid, old_tagcount = $get_info_from_sense_query.execute(key, synsetid).to_a.first rescue [nil, nil, nil,nil, nil, nil]

      # Dealing with words
      # no sense found for this word, prepare to make a new one
      if old_wordid.nil?
        wordid = $get_wordid_from_lemma.execute(word).to_a.first.first rescue nil
        # no wordid found for this word
        if wordid.nil?
          # create a new words entry
          $insert_new_word.execute(word)
          wordid = $get_wordid_from_lemma.execute(word).to_a.first.first
        end
      else
        old_word = $get_word_from_id.execute(old_wordid).to_a.first.first
        # conflict between old word and new word, use new word
        if old_word!=word
          $insert_new_word.execute(word)
          wordid = $get_wordid_from_lemma.execute(word).to_a.first.first
        else # same as before
          wordid = old_wordid
        end
      end


      # Dealing with casing
      # !! casing does not currently work to re-case a word as all lowercase
      # no case present: preserve old case, or just keeps as none
      if cased==word
        casedwordid = old_casedwordid
      # casing present, previous casing existed
      else
        if !old_casedwordid.nil?
          old_cased = $get_cased_from_id.execute(old_casedwordid).to_a.first.first
        else
          old_cased = nil
        end
        # conflict of casings
        if (old_cased!=cased || old_cased.nil?)
          # use new case, update casedwords if necessary
          casedwordid = $get_casedwordid_from_cased.execute(cased).to_a.first.first rescue nil
          if casedwordid.nil?
            $insert_new_casedword.execute(wordid,cased)
            casedwordid = $get_casedwordid_from_cased.execute(cased).to_a.first.first
          end
        else # same as before
          casedwordid = old_casedwordid
        end
      end

      # Dealing with senseid, nil if none found or new word, previous if found
      if wordid==old_wordid
        senseid = old_senseid
      # Dealing with sensenum, previous if found, else make a new one
        sensenum = old_sensenum
        tagcount = old_tagcount
        lexid = old_lexid
        print "old "
      else
        senseid = nil
        sensenum = new_sensenum(wordid, edit.pos)
        tagcount = nil
        lexid = 99
        print "new "
      end

      # possible old sensekey conflict
      if (old_word.nil? && different_key_already_exists?(key, synsetid))
        key = "#{word.downcase.gsub(" ","_")}%#{edit.pos}:#{lexid}:#{sensenum}::"
        edit.members[cased] = key
      end

      # new sensekey
      new_key = "#{word.downcase}##{sensenum}:#{edit.pos}"

      puts ":wid: #{wordid} :cid: #{casedwordid} :sid: #{synsetid} :senid: #{senseid}:snum: #{sensenum} :lid: #{lexid} :tg: #{tagcount} :key: #{key} :nky: #{new_key}"
      puts "    :wid: #{old_wordid} :cid: #{old_casedwordid} :sid: #{synsetid} :senid: #{old_senseid}:snum: #{old_sensenum} :lid: #{old_lexid} :tg: #{old_tagcount}"
      
      # add new to database
      if old_wordid.nil?
        $insert_new_sense_query.execute(wordid, casedwordid, synsetid, senseid, sensenum, lexid, tagcount, key, new_key)
      # change existing entry in database
      else
        $update_sense_query.execute(wordid,casedwordid,senseid,sensenum,lexid,tagcount,key,synsetid)
      end

    end
    
   
    edit.save

  end
end
