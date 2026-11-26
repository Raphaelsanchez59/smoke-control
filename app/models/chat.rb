class Chat < ApplicationRecord
  belongs_to :user, optional: true
  has_many :messages, dependent: :destroy

  def collecting?
    step == "smoker"
  end

  def awaiting_login?
    step == "awaiting_login"
  end

  def done?
    step == "done"
  end

  def missing_fields
    required = %w[nickname birth_year start_smoking_year smoker_type]
    required << "cigarettes_per_day" if %w[cigarette both].include?(profile_data["smoker_type"])
    required << "puffs_per_day"      if %w[e_cigarette both].include?(profile_data["smoker_type"])
    required.select { |field| profile_data[field].blank? }
  end

  def save_data_profile!(user) # rubocop:disable Metrics/MethodLength
    update!(user: user)

    user.update!(
      nickname: profile_data["nickname"],
      birth_date: Date.new(profile_data["birth_year"].to_i, 1, 1),
      start_smoking_year: profile_data["start_smoking_year"]
    )

    profile = user.smoker_profiles.create!(name: profile_data["nickname"], cigarette_type: profile_data["smoker_type"])

    if %w[cigarette both].include?(profile_data["smoker_type"])
      profile.cigarettes.create!(quantity_by_day: profile_data["cigarettes_per_day"],
                                 nicotine_mg: profile_data["cigarette_nicotine_mg"])
    end
    if %w[e_cigarette both].include?(profile_data["smoker_type"])
      profile.e_cigarettes.create!(puff_by_day: profile_data["puffs_per_day"],
                                   nicotine_mg: profile_data["ecig_nicotine_mg"])
    end

    profile.generate_profile!
    update!(step: "done", profile_data: {})
    profile
  end
end
