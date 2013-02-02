class AddPosandsemlinksToEdits < ActiveRecord::Migration
  def change
    add_column :edits, :pos, :string
    add_column :edits, :semlinks, :text
  end
end
