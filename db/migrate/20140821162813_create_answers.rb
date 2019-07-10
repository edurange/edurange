class CreateAnswers < ActiveRecord::Migration[4.2]
  def change
    create_table :answers do |t|
      t.integer :student_id
      t.string  :answer_text
      t.boolean :correct
      t.references :question, index: true
      t.timestamps
    end
  end
end
