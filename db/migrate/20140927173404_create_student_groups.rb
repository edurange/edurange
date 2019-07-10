class CreateStudentGroups < ActiveRecord::Migration[4.2]
  def change
    create_table :student_groups do |t|
      t.belongs_to  :user, null: false, default: ""
      t.string      :name, null: false, default: ""
      t.timestamps
    end
  end
end
