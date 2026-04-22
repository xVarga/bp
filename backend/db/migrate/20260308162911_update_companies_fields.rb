class UpdateCompaniesFields < ActiveRecord::Migration[8.1]
  def change
    add_column :companies, :street, :string
    add_column :companies, :zip, :string
    add_column :companies, :country, :string
    add_column :companies, :ico, :string
    add_column :companies, :dic, :string
    remove_column :companies, :address if column_exists?(:companies, :address)
  end
end