class AddPromptToBashHistories < ActiveRecord::Migration[5.2]
  def change
    add_column :bash_histories, :prompt, :string
  end
end
