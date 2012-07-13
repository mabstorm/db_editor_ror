class RemoveSemlinksFromEdits < ActiveRecord::Migration
  def up
    remove_column :edits, :semlinks
  end

  def down
    add_column :edits, :semlinks, :text
  end
end
