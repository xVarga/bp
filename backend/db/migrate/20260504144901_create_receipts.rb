class CreateReceipts < ActiveRecord::Migration[8.1]
  def change
    create_table :receipts do |t|
      t.integer :user_id
      t.string :merchant_name
      t.string :merchant_address
      t.string :dic
      t.string :ic_dph
      t.string :ico
      t.string :cash_register_code
      t.string :receipt_number
      t.datetime :issued_at
      t.decimal :total_amount

      t.timestamps
    end
  end
end
