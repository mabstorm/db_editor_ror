class AddExampleToEdit < ActiveRecord::Migration
  def change
    add_column :edits, :example, :string
    add_column :edits, :lexdomain, :string
  end
end
