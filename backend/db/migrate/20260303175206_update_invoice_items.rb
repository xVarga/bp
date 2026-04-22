class UpdateInvoiceItems < ActiveRecord::Migration[8.1]
  def change
    remove_column :invoice_items, :discount
    add_column :invoice_items, :vat_amount, :decimal
  end
end
