class SmokerProfile < ApplicationRecord
  CIGARETTE_TYPES = ["cigarette", "e_cigarette", "both"]
  belongs_to :user
  has_many :cigarettes, dependent: :destroy
  has_many :e_cigarettes, dependent: :destroy

  validates :cigarette_type, inclusion: { in: CIGARETTE_TYPES }, allow_blank: true
  validates :name, length: { maximum: 100 }, allow_blank: true
  validates :years_to_live,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 120 },
            allow_nil: true
  validates :content, length: { maximum: 5000 }, allow_blank: true
end
