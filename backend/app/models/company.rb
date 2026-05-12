class Company < ApplicationRecord
    belongs_to :user
    has_many :supplier_invoices, class_name: 'Invoice', foreign_key: 'supplier_id'
    has_many :customer_invoices, class_name: 'Invoice', foreign_key: 'customer_id'
    scope :active, -> { where(archived: false) }

    validates :company_name, presence: true
end