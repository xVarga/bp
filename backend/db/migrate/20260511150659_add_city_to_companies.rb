class AddCityToCompanies < ActiveRecord::Migration[8.1]
  def change
    add_column :companies, :city, :string
  end
end
