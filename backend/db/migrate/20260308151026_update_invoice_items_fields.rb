class UpdateInvoiceItemsFields < ActiveRecord::Migration[8.1]
  def change
    remove_column :invoice_items, :tax_base if column_exists?(:invoice_items, :tax_base)
    add_column :invoice_items, :total_without_vat, :decimal
    add_column :invoice_items, :total_with_vat, :decimal
  end
end
