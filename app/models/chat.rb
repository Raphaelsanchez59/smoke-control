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
    smoker_type = profile_data["smoker_type"].to_s.strip.downcase.tr("-", "_")
    required = ["nickname", "birth_year", "start_smoking_year"]
    required << "smoker_type" unless SmokerProfile::CIGARETTE_TYPES.include?(smoker_type)
    required << "cigarettes_per_day" if ["cigarette", "both"].include?(smoker_type)
    required << "puffs_per_day"      if ["e_cigarette", "both"].include?(smoker_type)
    required.select { |field| profile_data[field].blank? }
  end

  def consumption_profile_name
    cigarettes = profile_data["cigarettes_per_day"]
    puffs = profile_data["puffs_per_day"]
    smoker_type = profile_data["smoker_type"].to_s.strip.downcase.tr("-", "_")

    case smoker_type
    when "cigarette"
      "Cigarette - #{cigarettes}/day"
    when "e_cigarette"
      "E-cigarette - #{puffs} p/by"
    when "both"
      "Cigarette - #{cigarettes}/day + E-cigarette - #{puffs} p/by"
    else
      "Smoker profile"
    end
  end

  def save_data_profile!(user) # rubocop:disable Metrics/MethodLength
    smoker_type = profile_data["smoker_type"].to_s.strip.downcase.tr("-", "_")
    unless SmokerProfile::CIGARETTE_TYPES.include?(smoker_type)
      raise ArgumentError, "Unsupported smoker type: #{profile_data['smoker_type']}"
    end

    update!(user: user)

    user.update!(
      nickname: profile_data["nickname"],
      birth_date: Date.new(profile_data["birth_year"].to_i, 1, 1),
      start_smoking_year: profile_data["start_smoking_year"]
    )

    profile = user.smoker_profiles.create!(name: consumption_profile_name,
                                           cigarette_type: smoker_type)

    if ["cigarette", "both"].include?(smoker_type)
      profile.cigarettes.create!(quantity_by_day: profile_data["cigarettes_per_day"],
                                 nicotine_mg: profile_data["cigarette_nicotine_mg"])
    end
    if ["e_cigarette", "both"].include?(smoker_type)
      profile.e_cigarettes.create!(puff_by_day: profile_data["puffs_per_day"],
                                   nicotine_mg: profile_data["ecig_nicotine_mg"])
    end

    profile.generate_profile!
    update!(step: "done", profile_data: {})
    profile
  end
end
