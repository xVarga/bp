class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :password, length: { minimum: 6 }, if: :password_required?

  has_many :invoices
  has_many :companies
  has_many :receipts

  def full_name
    "#{first_name} #{last_name}"
  end

  private

  def password_required?
    new_record? || password.present?
  end
end