class UpdateSmokerProfileTool < RubyLLM::Tool
  description "Saves the smoker profile information given by the user. " \
              "Call it each time the user provides new information, passing only the fields they actually gave. " \
              "If the result contains 'rejected' values, kindly explain why they seem wrong and ask for them again."

  parameter :nickname, description: "User's first name or nickname", required: false
  parameter :birth_year, type: :integer, required: false,
                         description: "Year of birth. If the user provides their age, subtract the year from the current year."
  parameter :start_smoking_year, type: :integer, required: false,
                                 description: "Year the user started smoking. If “for X years”, deduct the year."
  parameter :smoker_type, required: false,
                          description: "Type of consumption: cigarette, e_cigarette or both. Use the underscore in e_cigarette."
  parameter :cigarettes_per_day, type: :integer, required: false,
                                 description: "Number of cigarettes per day"
  parameter :cigarette_nicotine_mg, type: :number, required: false,
                                    description: "Nicotine per cigarette in mg, only if the user knows it."
  parameter :puffs_per_day, type: :integer, required: false,
                            description: "Estimated number of e-cigarette puffs per day"
  parameter :ecig_nicotine_mg, type: :number, required: false,
                               description: "Nicotine content of the e-liquid in mg."

  LIMITS = {
    "cigarettes_per_day" => 1..200,
    "cigarette_nicotine_mg" => 0..3,
    "ecig_nicotine_mg" => 0..50
  }

  def initialize(chat:)
    @chat = chat
  end

  def execute(nickname: nil, birth_year: nil, start_smoking_year: nil, smoker_type: nil, # rubocop:disable Metrics/MethodLength,Metrics/ParameterLists
              cigarettes_per_day: nil, cigarette_nicotine_mg: nil, puffs_per_day: nil, ecig_nicotine_mg: nil)
    return { error: "Profile already complete" } unless @chat.collecting?

    smoker_type = smoker_type.to_s.strip.downcase.tr("-", "_")
    smoker_type = nil unless SmokerProfile::CIGARETTE_TYPES.include?(smoker_type)
    profile_values = {
      "nickname" => nickname, "birth_year" => birth_year, "start_smoking_year" => start_smoking_year,
      "smoker_type" => smoker_type, "cigarettes_per_day" => cigarettes_per_day,
      "cigarette_nicotine_mg" => cigarette_nicotine_mg, "puffs_per_day" => puffs_per_day,
      "ecig_nicotine_mg" => ecig_nicotine_mg
    }
    new_values = profile_values.select { |_key, value| value.present? }
    errors = errors_for(new_values)
    new_values = new_values.except(*errors.keys)

    @chat.update!(profile_data: @chat.profile_data.merge(new_values))

    missing = @chat.missing_fields
    @chat.update!(step: "awaiting_login") if missing.empty?

    Turbo::StreamsChannel.broadcast_update_to(
      [@chat, :side_profile],
      target: ActionView::RecordIdentifier.dom_id(@chat, :side_profile),
      partial: "chats/side_profile",
      locals: { chat: @chat }
    )

    { saved: new_values, rejected: errors, profile: @chat.profile_data, missing: missing, complete: missing.empty? }
  end

  private

  def errors_for(values)
    errors = {}
    year = Date.current.year

    LIMITS.each do |field, range|
      next if values[field].nil?

      errors[field] = "must be between #{range.min} and #{range.max}" unless range.cover?(values[field].to_f)
    end

    if values["birth_year"] && !((year - 120)..(year - 18)).cover?(values["birth_year"].to_i)
      errors["birth_year"] = "the user must be between 18 and 120 years old"
    end

    start = values["start_smoking_year"]
    birth = values["birth_year"] || @chat.profile_data["birth_year"]
    if start
      errors["start_smoking_year"] = "cannot be in the future" if start.to_i > year
      errors["start_smoking_year"] = "cannot be before the year of birth" if birth && start.to_i < birth.to_i
    end

    errors
  end
end
