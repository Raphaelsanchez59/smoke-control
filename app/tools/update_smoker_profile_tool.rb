class UpdateSmokerProfileTool < RubyLLM::Tool
  description "Saves the smoker profile information given by the user. " \
              "Call it each time the user provides new information, passing only the fields they actually gave."

  parameter :nickname, description: "User's first name or nickname", required: false
  parameter :birth_year, type: :integer, required: false,
                         description: "Year of birth. If the user provides their age, subtract the year from the current year."
  parameter :start_smoking_year, type: :integer, required: false,
                                 description: "Year the user started smoking. If “for X years”, deduct the year."
  parameter :smoker_type, required: false,
                          description: "Type of consumption, exactly: cigarette, e-cigarette or both"
  parameter :cigarettes_per_day, type: :integer, required: false,
                                 description: "Number of cigarettes per day"
  parameter :cigarette_nicotine_mg, type: :number, required: false,
                                    description: "Nicotine per cigarette in mg, only if the user knows it."
  parameter :puffs_per_day, type: :integer, required: false,
                            description: "Estimated number of e-cigarette puffs per day"
  parameter :ecig_nicotine_mg, type: :number, required: false,
                               description: "Nicotine content of the e-liquid in mg."

  def initialize(chat:)
    @chat = chat
  end

  def execute(nickname: nil, birth_year: nil, start_smoking_year: nil, smoker_type: nil, # rubocop:disable Metrics/MethodLength,Metrics/ParameterLists
              cigarettes_per_day: nil, cigarette_nicotine_mg: nil, puffs_per_day: nil, ecig_nicotine_mg: nil)
    return { error: "Profile already complete" } unless @chat.collecting?

    profile_values = {
      "nickname" => nickname, "birth_year" => birth_year, "start_smoking_year" => start_smoking_year,
      "smoker_type" => smoker_type, "cigarettes_per_day" => cigarettes_per_day,
      "cigarette_nicotine_mg" => cigarette_nicotine_mg, "puffs_per_day" => puffs_per_day,
      "ecig_nicotine_mg" => ecig_nicotine_mg
    }
    new_values = profile_values.select { |_key, value| value.present? }

    @chat.update!(profile_data: @chat.profile_data.merge(new_values))

    missing = @chat.missing_fields
    @chat.update!(step: "awaiting_login") if missing.empty?

    { saved: new_values, profile: @chat.profile_data, missing: missing, complete: missing.empty? }
  end
end
