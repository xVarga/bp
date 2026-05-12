class Receipt < ApplicationRecord
    belongs_to :user
    has_many :receipt_items
    accepts_nested_attributes_for :receipt_items
end
