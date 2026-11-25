class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :smoker_profiles, dependent: :destroy
  has_many :chats, dependent: :destroy
  validates :birth_date, presence: true

  validate :start_smoking_year_coherent
  validate :must_be_at_least18

  def adult?
    birth_date.present? && birth_date <= 18.years.ago.to_date
  end

  def active_for_authentication?
    super && adult?
  end

  def inactive_message
    adult? ? super : :underage
  end

  private

  def start_smoking_year_coherent
    return if start_smoking_year.blank?
    return unless birth_date.present? && start_smoking_year < birth_date.year

    errors.add(:start_smoking_year, "cannot be before the birth year")
  end

  def must_be_at_least18
    return if birth_date.blank?

    errors.add(:birth_date, "must be at least 18 years old") unless adult?
  end
end
