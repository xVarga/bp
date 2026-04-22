class AddVatExemptToInvoices < ActiveRecord::Migration[8.1]
  def change
    add_column :invoices, :vat_exempt, :boolean, default: false
  end
end
