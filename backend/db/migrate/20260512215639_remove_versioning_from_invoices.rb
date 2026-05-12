class RemoveVersioningFromInvoices < ActiveRecord::Migration[8.1]
  def change
    remove_column :invoices, :parent_id
  end
end
