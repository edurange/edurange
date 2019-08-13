class AddSecretToScenarios < ActiveRecord::Migration[5.2]
  def change
    add_column :scenarios, :secret, :string
  end
end
