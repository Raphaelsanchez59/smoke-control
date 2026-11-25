class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :smoker_profiles, dependent: :destroy
  has_many :chats, dependent: :destroy
  validate :start_smoking_year_coherent

  private

  def start_smoking_year_coherent
    return if start_smoking_year.blank?

    if start_smoking_year > Date.current.year
      errors.add(:start_smoking_year, "cannot be in the future")
    elsif birth_date.present? && start_smoking_year < birth_date.year
      errors.add(:start_smoking_year, "cannot be before the birth year")
    end
  end
end
