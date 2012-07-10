class EditsController < ApplicationController
  include EditsHelper, InfogetterHelper
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

    if params.has_key?(:sort_by)
      @sort_by = params[:sort_by]
    elsif session.has_key?(:sort_by)
      params.merge!(:sort_by => session[:sort_by])
      redirect = true
    else
      @sort_by = ""
    end
    (flash.keep; return redirect_to params) if redirect

    session[:sort_by] = @sort_by
    @all_edits = Edit.order(@sort_by)
  end

  def new
    return force_login if !admin?
  end

  def create
    return force_login if !admin?
    @edit = Edit.create!({"synsetid"=>params[:edit][:synsetid],"definition"=>params[:edit][:definition]})
    @edit.update_attribute("members", deserialize_members(params[:members]))
    flash[:notice] = "#{@edit.synsetid} was successfully created."
    redirect_to edit_edit_path(@edit)
  end

  def edit
    return force_login if !admin?
    @edit = Edit.find_by_id(params[:id])

    if @edit.nil?
      params[:edit] = Hash.new
      params[:edit][:synsetid] = 0
      params[:edit][:definition] = ""
      create
    end
    @message = flash[:notice]
  end

  def update
    return force_login if !admin?
    @edit = Edit.find params[:id]
    message = nil
    if (params[:add_member])
      add_member_action
      message = 'added'
    elsif (params[:delete_members])
      delete_member_action
      message = 'deleted'
    elsif (params[:update_members])
      update_members_action
      message = 'updated'
    end

    update_from_params(@edit) if message

    # searching for something on the side using Freebase
    update_freebase_session

    # update the session based on the wordnet query section
    wordnet_query_session

    #@edit.update_attributes!(params[:edit])
    flash[:notice] = "#{@edit.synsetid} was successfully #{message}." if !message.nil?
    redirect_to edit_edit_path(@edit)
  end

  def destroy
    return force_login if !admin?
    @edit = Edit.find(params[:id])
    @edit.destroy
    flash[:notice] = "Edit '#{@edit.synsetid}' deleted."
    redirect_to edits_path
  end
end
