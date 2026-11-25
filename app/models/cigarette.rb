class Cigarette < ApplicationRecord
  belongs_to :smoker_profile
  validates :quantity_by_day,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 200 },
            allow_nil: true
  validates :nicotine_mg,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5.0 },
            allow_nil: true
end
