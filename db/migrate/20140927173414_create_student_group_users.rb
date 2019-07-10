class CreateStudentGroupUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :student_group_users do |t|
      t.belongs_to  :student_group
      t.belongs_to  :user
      t.timestamps
    end
  end
end
