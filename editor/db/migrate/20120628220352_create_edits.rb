class CreateEdits < ActiveRecord::Migration
  def change
    create_table :edits do |t|
      t.integer :synsetid
      t.text :definition
      t.text :members

      t.timestamps
    end
  end
end
