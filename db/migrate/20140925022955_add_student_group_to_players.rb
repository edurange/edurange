class AddStudentGroupToPlayers < ActiveRecord::Migration[4.2]
  def change
    add_column :players, :student_group_id, :integer
  end
end
