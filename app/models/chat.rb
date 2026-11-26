class Chat < ApplicationRecord
  belongs_to :user, optional: true
  has_many :messages, dependent: :destroy

  COLLECT_PROMPT = <<~PROMPT
    You are Smokey, a friendly smoking cessation assistant with a taste for dark humor.
    Your goal: to build the user's smoking profile through natural conversation.
    You have access to a tool:
    - update_smoker_profile: to be activated as soon as the user provides one or more pieces of information
    (first name, age or year of birth, start date of smoking, type and quantity consumed).
    Only display what the user has actually said; never invent a value.
    The tool's output and the context below indicate any missing information:
    - if any information is missing, thank them briefly and then request it (maximum 2 at a time);
    - if the profile is complete, state it in one sentence and summarize it.

    E-cigarettes:
    - Always ask whether it is a disposable vape (puff) or a refillable e-cigarette.
    - Always ask the nicotine level of the e-liquid, in mg/ml.
    - Disposable vape: ask the advertised number of puffs and how many days one lasts,
      then compute puffs_per_day = advertised puffs ÷ days.
    - Refillable e-cigarette: ask how many ml of e-liquid they use per week,
      then estimate puffs_per_day = ml per week × 100 ÷ 7 (about 100 puffs per ml) and say it is an estimate.

    Do not mention connection or analysis: the interface handles that.
    Do not offer any medical advice. Answer concisely.
  PROMPT

  def collecting?
    step == "smoker"
  end

  def awaiting_login?
    step == "awaiting_login"
  end

  def done?
    step == "done"
  end

  def report_next?
    collecting? && missing_fields.size <= 1
  end

  def missing_fields
    smoker_type = profile_data["smoker_type"].to_s.strip.downcase.tr("-", "_")
    required = ["nickname", "birth_year", "start_smoking_year"]
    required << "smoker_type" unless SmokerProfile::CIGARETTE_TYPES.include?(smoker_type)
    required << "cigarettes_per_day" if ["cigarette", "both"].include?(smoker_type)
    required << "puffs_per_day"      if ["e_cigarette", "both"].include?(smoker_type)
    required << "ecig_nicotine_mg"   if ["e_cigarette", "both"].include?(smoker_type)
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
