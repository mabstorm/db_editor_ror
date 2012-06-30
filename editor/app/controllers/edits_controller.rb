class EditsController < ApplicationController
  include EditsHelper
  def show
    id = params[:id] # retrieve edit ID from URI route
    @edit = Edit.find(id) # look up edit by unique ID
    # will render app/views/edits/show.<extension> by default
  end

  def index
    redirect = false
=begin
    if params.has_key?(:synsetid)
      @current_ratings = params[:synsetid]
    elsif session.has_key?(:synsetid)
      params.merge!(:synsetid => session[:synsetid])
      redirect = true
    else
      @current_ratings = Hash.new
    end
=end
    if params.has_key?(:sort_by)
      @sort_by = params[:sort_by]
    elsif session.has_key?(:sort_by)
      params.merge!(:sort_by => session[:sort_by])
      redirect = true
    else
      @sort_by = ""
    end
    (flash.keep; redirect_to params) if redirect
    #@current_ratings = params[:synsetid] if @current_ratings.nil?
    #@edits = Edit.where(:rating => @current_ratings.keys).order(@sort_by)
    #@all_options = options
    session[:sort_by] = @sort_by
    #session[:synsetid] = @current_ratings
    @all_edits = Edit.order(@sort_by)
  end

  def new
    
  end

  def create
    @edit = Edit.create!({"synsetid"=>params[:edit][:synsetid],"definition"=>params[:edit][:definition]})
    @edit.update_attribute("members", deserialize_members(params[:members]))
    flash[:notice] = "#{@edit.synsetid} was successfully created."
    redirect_to edit_edit_path(@edit)
  end

  def edit
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
    @edit = Edit.find params[:id]
    message = nil
    if (params[:add_member])
      if params[:members].nil?
        params[:members] = Hash.new
      end
      params[:members]['new entry'] = ''
      params[:members]['new entry|'] = ''
      message = 'added'
    elsif (params[:delete_members])
      params[:check_box].each_pair do |mem,to_del|
        if (to_del=="1")
          params[:members].delete("old_#{mem.gsub('delete_','')}") 
        end
      end
      params[:members] = clean_hash(params[:members])
      message = 'deleted'
    elsif (params[:update_members])
      params[:members] = clean_hash(params[:members])
      message = 'updated'
    end
    @edit.update_attribute("synsetid", params[:edit][:synsetid])
    @edit.update_attribute("definition", params[:edit][:definition])
    @edit.update_attribute("members", deserialize_members(params[:members]))


    #@edit.update_attributes!(params[:edit])
    flash[:notice] = "#{@edit.synsetid} was successfully #{message}." if !message.nil?
    redirect_to edit_edit_path(@edit)
  end

  def destroy
    @edit = Edit.find(params[:id])
    @edit.destroy
    flash[:notice] = "Edit '#{@edit.synsetid}' deleted."
    redirect_to edits_path
  end
end
