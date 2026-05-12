class CreateReceiptItems < ActiveRecord::Migration[8.1]
  def change
    create_table :receipt_items do |t|
      t.integer :receipt_id
      t.string :description
      t.decimal :quantity
      t.decimal :unit_price
      t.decimal :total_price

      t.timestamps
    end
  end
end
