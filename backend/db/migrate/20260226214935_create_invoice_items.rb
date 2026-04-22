class CreateInvoiceItems < ActiveRecord::Migration[8.1]
  def change
    create_table :invoice_items do |t|
      t.string :description
      t.decimal :quantity
      t.decimal :unit_price
      t.decimal :discount
      t.decimal :tax_rate
      t.decimal :tax_base
      t.integer :invoice_id

      t.timestamps
    end
  end
end
