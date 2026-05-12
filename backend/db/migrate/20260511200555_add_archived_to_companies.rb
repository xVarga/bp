class AddArchivedToCompanies < ActiveRecord::Migration[8.1]
  def change
    add_column :companies, :archived, :boolean, default: false
  end
end
