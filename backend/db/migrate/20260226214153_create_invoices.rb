class CreateInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :invoices do |t|
      t.string :invoice_number
      t.date :issue_date
      t.date :delivery_date
      t.decimal :total_vat_amount
      t.integer :user_id
      t.integer :supplier_id
      t.integer :customer_id
      t.boolean :is_cancelled, default: false
      t.integer :version, default: 1
      t.integer :parent_id

      t.timestamps
    end
  end
end
