class AddVariousToEdits < ActiveRecord::Migration
  def change
    add_column :edits, :author, :string
    add_column :edits, :status, :integer, :default => 0
  end
end
