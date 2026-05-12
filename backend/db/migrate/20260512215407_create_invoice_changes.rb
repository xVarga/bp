class CreateInvoiceChanges < ActiveRecord::Migration[8.1]
  def change
    create_table :invoice_changes do |t|
      t.integer :invoice_id
      t.string :field_name
      t.text :old_value
      t.datetime :changed_at

      t.timestamps
    end
  end
end
