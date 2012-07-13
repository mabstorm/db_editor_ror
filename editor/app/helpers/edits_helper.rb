module EditsHelper
  include WnQueriesHelper
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
      new_arr[1] = "#{new_arr[0].downcase.gsub(/\s/,'_')}%1:18:00::" if (new_arr[1].to_s=="" && new_arr[0]!="")
      members_hash[new_arr[0].to_s] = new_arr[1].to_s
    end
    members_hash = {""=>""} if members_hash.empty?
    return members_hash
  end



  def clean_hash(hash)
    hash.delete_if {|k,v| k==""||v==""}
    return hash
  end

  def create_blank_edit
    params[:edit] = Hash.new
    params[:edit][:synsetid] = 0
    params[:edit][:definition] = ""
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
        params[:members].delete("old_#{mem.gsub('delete_','')}") 
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
    if (is_blank edit)
      edit.update_attributes({"synsetid" => new_synset.synsetid,
                          "definition" => new_synset.definition,
                          "members" => new_synset.members_and_keys})
    else
      @edit = Edit.create({"synsetid" => new_synset.synsetid,
                          "definition" => new_synset.definition,
                          "members" => new_synset.members_and_keys})
    end
    flash[:notice] = "#{@edit.synsetid} was successfully imported"
    redirect_to edit_edit_path(@edit)
  end

  def render_wordnet_interface f
    chosen_synset, wnresults = wordnet_query(session[:wordnetquery], session[:chosen_synsetid])
    render :file => 'app/views/wn_queries/query', :locals => {:f => f, :chosen_synset => chosen_synset, :wnresults => wnresults, :queryval => session[:wordnetquery] }, :handlers => [:haml]
  end

  def render_semlinks(f, synsetid)
    semlinks = WnQueriesHelper.get_semlinks(synsetid)
    render :file => 'app/views/edits/semlinks', :locals => {:f => f, :semlinks => semlinks, :all_links => $all_links}, :handlers => [:haml]
  end


  def render_freebase_interface f
    session[:this_query] = nil
    results = query(session[:freebasequery])
    render :file => 'app/views/infogetter/query', :locals => {:f => f, :freebasequery => session[:freebasequery], :results => results}, :handlers => [:haml]
  end
end
