class AddSemlinksFromEdits < ActiveRecord::Migration
  def change
    add_column :edits, :semlinks, :text
  end
end
