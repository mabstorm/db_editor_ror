class AddLexdomainidToEdits < ActiveRecord::Migration
  def change
    add_column :edits, :lexdomainid, :integer
  end
end
