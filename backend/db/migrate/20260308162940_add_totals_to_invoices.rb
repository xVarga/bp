class AddTotalsToInvoices < ActiveRecord::Migration[8.1]
  def change
    add_column :invoices, :total_without_vat, :decimal
    add_column :invoices, :total_with_vat, :decimal
  end
end