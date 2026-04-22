class UpdateCompanies < ActiveRecord::Migration[8.1]
  def change
    rename_column :companies, :name, :company_name
    rename_column :companies, :vat_number, :ic_dph
    add_column :companies, :type, :string
    add_column :companies, :first_name, :string
    add_column :companies, :last_name, :string 
  end
end
