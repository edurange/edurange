class UpdateQuestionAndAnswers < ActiveRecord::Migration[4.2]
  def change
  	# update questions
  	remove_column :questions, :answer_id
  	remove_column :questions, :kind
  	remove_column :questions, :question_text
  	remove_column :questions, :answer_text

  	add_column :questions, :order, :integer
  	add_column :questions, :text, :string
  	add_column :questions, :type_of, :string
  	add_column :questions, :options, :string, default: [].to_yaml
  	add_column :questions, :values, :string
  	add_column :questions, :points, :integer
  	add_column :questions, :points_penalty, :integer

  	# update answers
  	remove_column :answers, :student_id
  	remove_column :answers, :answer_text

  	add_column :answers, :text, :string
  	add_column :answers, :text_essay, :text
  	add_column :answers, :comment, :text
  	add_column :answers, :value_index, :integer
  	add_column :answers, :essay_points_earned, :string
  	add_reference :answers, :user

  end
end
