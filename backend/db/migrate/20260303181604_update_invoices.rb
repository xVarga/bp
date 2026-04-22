class UpdateInvoices < ActiveRecord::Migration[8.1]
  def change
    add_column :invoices, :self_billed, :boolean, default: false
    add_column :invoices, :reverse_charge, :boolean, default: false
    add_column :invoices, :travelling_agency, :boolean, default: false
    add_column :invoices, :used_item, :boolean, default: false
    add_column :invoices, :art, :boolean, default: false
    add_column :invoices, :collectibles, :boolean, default: false
  end
end