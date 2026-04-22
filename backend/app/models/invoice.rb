class Invoice < ApplicationRecord
    belongs_to :user
    belongs_to :supplier, class_name: 'Company', foreign_key: 'supplier_id', optional: true
    belongs_to :customer, class_name: 'Company', foreign_key: 'customer_id', optional: true
    has_many :invoice_items
    accepts_nested_attributes_for :invoice_items

    validates :invoice_number, presence: true
    validates :issue_date, presence: true
    validates :delivery_date, presence: true
end
