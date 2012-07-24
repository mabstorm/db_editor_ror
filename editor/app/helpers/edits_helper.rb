module EditsHelper
  include WnQueriesHelper
  # reset the entire members hash using the params
  def deserialize_members(members)  
    members_info = Hash.new
    if !members.nil?
      members.each_pair do |name, value|
        old_name = name.gsub(/\|.*$/,'')
        members_info[old_name] = Array.new if members_info[old_name].nil?
        if name.include?('|')
          members_info[old_name][1] = value #if value!=""# sensekey
        else
          members_info[old_name][0] = value #if value!=""# word
        end
      end
    end
    members_hash = Hash.new
    members_info.each_pair do |old_name, new_arr|
      next if new_arr[0].nil?
      if (new_arr[1].to_s=="" && new_arr[0]!="")
        pos = $pos_map.index(params[:edit][:pos])+1 rescue 1 #default to noun
        new_arr[1] = "#{new_arr[0].downcase.gsub(/\s/,'_')}%1:18:00::"
      end
      members_hash[new_arr[0].to_s] = new_arr[1].to_s
    end
    members_hash = {""=>""} if members_hash.empty?
    return members_hash
  end


  # resets the entire semlinks array of pairs
  def deserialize_semlinks(semlinks)
    links = Hash.new
    unless semlinks.nil?
      semlinks.each_pair do |passed_name, value|
        name = passed_name.gsub('_', '|')
        next if name.empty?
        links[name] = Array.new if links[name].nil?
        # setting synset2id
        links[name][1] = value if passed_name.include? '|' # synset2id
        # setting linktype
        links[name][0] = value if passed_name.include? '_' # linktype
      end
    end
    # check to see if all links had a matching set
    links.each_pair do |name, semlink|
      links.delete(name) if (semlink.nil? || semlink[0].nil? || semlink[1].nil? || semlink[0].empty? || semlink[1].empty?)
    end

    if params[:create_semlink]
      name = "___" # temp name...
      links[name] = Array.new
      links[name][1] = params[:create_semlink]
      links[name][0] = "hypernym"
      params[:create_semlink] = nil
    end
    params[:semlinks] = links.values
    puts "*****************#{links.values}***************"
    return links.values
  end


  # remove empty members
  def clean_hash(hash)
    hash.delete_if {|k,v| k==""||v==""}
    return hash
  end

  def create_blank_edit
    params[:edit] = Hash.new
    params[:edit][:synsetid] = 0
    params[:edit][:definition] = ""
    params[:edit][:pos] = "n"
    create
  end


  def add_member_action
    if params[:members].nil?
      params[:members] = Hash.new
    end
    params[:members]['new entry'] = ''
    params[:members]['new entry|'] = ''
  end

  def delete_member_action
    params[:check_box].each_pair do |mem,to_del|
      if (to_del=="1")
        to_delete = "#{mem.gsub('delete_','')}"
        params[:members].delete("old_#{to_delete}") 
      end
    end
    params[:semlinks_check_box].each_pair do |mem,to_del|
      if (to_del=="1")
        to_delete = "#{mem.gsub('delete_','')}"
        params[:semlinks].delete(to_delete)
        params[:semlinks].delete(to_delete.gsub('_','|'))
      end
    end

    params[:members] = clean_hash(params[:members])
  end

  def update_members_action
    params[:members] = clean_hash(params[:members])
  end

  def update_from_params(edit)
=begin
    edit.update_attribute("synsetid", params[:edit][:synsetid])
    edit.update_attribute("definition", params[:edit][:definition])
    edit.update_attribute("members", deserialize_members(params[:members]))
=end
    edit.update_attributes({"synsetid" => params[:edit][:synsetid],
                          "definition" => params[:edit][:definition],
                          "pos" => params[:edit][:pos],
                          "semlinks" => deserialize_semlinks(params[:semlinks]),
                          "members" => deserialize_members(params[:members])})

  end

  def sort_for_column(column)
    @sort_by == column && @sort_direction == "ASC" ? "DESC" : "ASC"
  end

  def is_blank(edit)
    edit.synsetid==0 && edit.definition == ""
  end

  def new_from_synset(edit)
    new_synset = Synset.new(params[:synsetid])
    new_synset.set_semlinks
    if (is_blank edit)
      edit.update_attributes({"synsetid" => new_synset.synsetid,
                          "definition" => new_synset.definition,
                          "pos" => new_synset.pos,
                          "members" => new_synset.members_and_keys,
                          "semlinks" => new_synset.semlinks})
    else
      @edit = Edit.create({"synsetid" => new_synset.synsetid,
                          "definition" => new_synset.definition,
                          "pos" => new_synset.pos,
                          "members" => new_synset.members_and_keys,
                          "semlinks" => new_synset.semlinks})
    end
    flash[:notice] = "#{@edit.synsetid} was successfully imported"
    redirect_to edit_edit_path(@edit)
  end

  def render_wordnet_interface f
    chosen_synset, wnresults = wordnet_query(session[:wordnetquery], session[:chosen_synsetid])
    render :file => 'app/views/wn_queries/query', :locals => {:f => f, :chosen_synset => chosen_synset, :wnresults => wnresults, :queryval => session[:wordnetquery] }, :handlers => [:haml] 
  end

  def render_semlinks(f, synsetid, edit)
    if edit.semlinks.nil?
      puts "+++++++++++finding new semlinks+++++++++++"
      semlinks = WnQueriesHelper.get_semlinks(synsetid)
    else
      puts "++USING OLD SEMLINKS++"
      semlinks = edit.semlinks
    end
    render :file => 'app/views/edits/semlinks', :locals => {:f => f, :semlinks => semlinks, :all_links => $all_links}, :handlers => [:haml]
  end


  def render_freebase_interface f
    session[:this_query] = nil
    results = query(session[:freebasequery])
    render :file => 'app/views/infogetter/query', :locals => {:f => f, :freebasequery => session[:freebasequery], :results => results}, :handlers => [:haml]
  end
end
