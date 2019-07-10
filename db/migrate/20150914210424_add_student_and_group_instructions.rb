class AddStudentAndGroupInstructions < ActiveRecord::Migration[4.2]
  def change
  	remove_column :scenarios, :instructions
  	add_column :scenarios, :instructions, :text, default: ""
  	add_column :scenarios, :instructions_student, :text, default: ""
  	add_column :groups, :instructions, :text, default: ""
  end
end
