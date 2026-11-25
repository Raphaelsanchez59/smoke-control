class ECigarette < ApplicationRecord
  belongs_to :smoker_profile

  validates :puff_by_day,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 10_000 },
            allow_nil: true
  validates :nicotine_mg,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 60.0 },
            allow_nil: true
end
