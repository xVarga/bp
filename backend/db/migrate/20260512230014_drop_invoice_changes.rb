class DropInvoiceChanges < ActiveRecord::Migration[8.1]
  def change
      drop_table :invoice_changes
  end
end
