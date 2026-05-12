class AddCurrencyToInvoices < ActiveRecord::Migration[8.1]
  def change
    add_column :invoices, :currency, :string
  end
end
