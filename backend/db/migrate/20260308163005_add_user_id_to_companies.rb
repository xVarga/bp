class AddUserIdToCompanies < ActiveRecord::Migration[8.1]
  def change
    add_column :companies, :user_id, :integer
  end
end