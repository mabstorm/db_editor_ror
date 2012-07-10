module EditsHelper
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
    edit.update_attribute("synsetid", params[:edit][:synsetid])
    edit.update_attribute("definition", params[:edit][:definition])
    edit.update_attribute("members", deserialize_members(params[:members]))  end


end
