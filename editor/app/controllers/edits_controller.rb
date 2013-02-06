class EditsController < ApplicationController
  include EditsHelper, InfogetterHelper, WnQueriesHelper
  def show
    return force_login if !admin?
    id = params[:id] # retrieve edit ID from URI route
    @edit = Edit.find(id) # look up edit by unique ID
    # will render app/views/edits/show.<extension> by default
  end

  def force_login
    redirect_to login_path
  end

  def index
    return force_login if !admin?
    redirect = false
    session[:wordnetquery] = nil
    session[:freebasequery] = nil

    if params.has_key?(:sort_by)
      @sort_by = params[:sort_by]
    elsif session.has_key?(:sort_by)
      params.merge!(:sort_by => session[:sort_by])
      redirect = true
    else
      @sort_by = "updated_at"
    end
    if params.has_key?(:sort_direction)
      @sort_direction = params[:sort_direction]
    elsif session.has_key?(:sort_direction)
      params.merge!(:sort_direction => session[:sort_direction])
      redirect = true
    else
      @sort_direction = "DESC"
    end
    (flash.keep; return redirect_to params) if redirect

    session[:sort_by] = @sort_by
    session[:sort_direction] = @sort_direction
    if @sort_by==:updated_at
      @all_edits = Edit.order("DATE(#{@sort_by}) #{@sort_direction}")
    else
      @all_edits = Edit.order("#{@sort_by} #{@sort_direction}")
    end
  end

  def new
    return force_login if !admin?
  end

  def create
    return force_login if !admin?
    @edit = Edit.create!({"synsetid"=>params[:edit][:synsetid],"definition"=>params[:edit][:definition],"pos"=>params[:edit][:pos]})
    @edit.update_attribute("members", deserialize_members(params[:members]))
    @edit.update_attribute("semlinks", deserialize_semlinks(params[:semlinks]))
    update_lexdomainid(@edit)
    flash[:notice] = "#{@edit.synsetid} was successfully created."
    redirect_to edit_edit_path(@edit)
  end

  def edit
    return force_login if !admin?
    @edit = Edit.find_by_id(params[:id])

    if @edit.nil?
      return create_blank_edit
    end
    @message = flash[:notice]
    
    update
  end

  # always gets called by edit
  def update
    return force_login if !admin?
    @edit = Edit.find params[:id]
    message = nil

    @edit.author = session[:username]
    @edit.save

    if (params[:synsetid])
      new_from_synset @edit
    end

    if (params[:add_member])
      add_member_action
      message = 'added member'
    elsif (params[:delete_members])
      delete_member_action
      message = 'deleted member'
    elsif (params[:update_members])
      update_members_action
      message = 'updated member'
    elsif (params[:create_semlink])
      message = 'added semlink'
    elsif (params[:create_lexlink])
      message = 'added lexlink'
    end

    if (params[:search_this])
      session[:wordnetquery] = params[:search_this]
      params[:wordnet][:query] = params[:search_this]
    end

    update_from_params(@edit) if message
    update_lexdomainid(@edit)

    # searching for something on the side using Freebase
    update_freebase_session

    # update the session based on the wordnet query section
    wordnet_query_session

    #@edit.update_attributes!(params[:edit])
    @incomplete_message = ''
    @incomplete_message += '  hypernym\n' unless has_hypernym?(@edit.semlinks)
    @incomplete_message += '  definition\n' unless (!@edit.definition.nil? && @edit.definition.length > 0);
    flash[:notice] = "#{message}." if !message.nil?
    @message = message;
    #redirect_to edit_edit_path(@edit)
  end

  def apply
    return force_login if !admin?
    @edit = Edit.find(params[:id])
    WnQueriesHelper.apply_edit_to_database(@edit)
    #flash[:notice] = ": ##{@edit.id} applied to database successfully"
    redirect_to edits_path
  end

  def apply_all
    Edit.all.each {|edit| WnQueriesHelper.apply_edit_to_database(edit) }
    flash[:notice] = "applied to database successfully"
    redirect_to edits_path
  end

  def destroy
    return force_login if !admin?
    @edit = Edit.find(params[:id])
    @edit.destroy
    flash[:notice] = "Edit '#{@edit.synsetid}' deleted."
    redirect_to edits_path
  end
end
