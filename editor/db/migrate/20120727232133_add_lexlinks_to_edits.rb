class AddLexlinksToEdits < ActiveRecord::Migration
  def change
    add_column :edits, :lexlinks, :text
  end
end
