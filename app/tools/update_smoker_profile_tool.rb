class UpdateSmokerProfileTool < RubyLLM::Tool
  description "Saves the smoker profile information given by the user. " \
              "Call it on every user message with only profile facts explicitly stated in that message. " \
              "It compares new values with saved values and replaces only values that changed. " \
              "Omitting a value leaves its saved value unchanged. " \
              "If the result contains 'rejected' values, kindly explain why they seem wrong and ask for them again."

  parameter :nickname, description: "User's first name or nickname", required: false
  parameter :birth_year, type: :integer, required: false,
                         description: "Four-digit year of birth. Use age instead when the user gives their age."
  parameter :age, type: :integer, required: false, description: "User's age in years"
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

  def execute(nickname: nil, birth_year: nil, age: nil, start_smoking_year: nil, smoker_type: nil, # rubocop:disable Metrics/MethodLength,Metrics/ParameterLists
              cigarettes_per_day: nil, cigarette_nicotine_mg: nil, puffs_per_day: nil, ecig_nicotine_mg: nil)
    unless @chat.collecting? || @chat.awaiting_login? || @chat.done?
      return { error: "Profile cannot be updated in its current state" }
    end

    current_data = @chat.profile_data
    if @chat.done?
      user = @chat.user
      profile = @chat.smoker_profile
      return { error: "Saved profile not found" } unless user && profile

      cigarette = profile.cigarettes.order(:created_at).last
      e_cigarette = profile.e_cigarettes.order(:created_at).last
      current_data = {
        "nickname" => user.nickname,
        "birth_year" => user.birth_date&.year,
        "start_smoking_year" => user.start_smoking_year,
        "smoker_type" => profile.cigarette_type,
        "cigarettes_per_day" => cigarette&.quantity_by_day,
        "cigarette_nicotine_mg" => cigarette&.nicotine_mg,
        "puffs_per_day" => e_cigarette&.puff_by_day,
        "ecig_nicotine_mg" => e_cigarette&.nicotine_mg
      }.select { |_key, value| value.present? }
       .merge(current_data.select { |_key, value| value.present? })
    end

    smoker_type = smoker_type.to_s.strip.downcase.tr("-", "_")
    smoker_type = nil unless SmokerProfile::CIGARETTE_TYPES.include?(smoker_type)
    birth_year = Date.current.year - age.to_i if age.present?

    profile_values = {
      "nickname" => nickname, "birth_year" => birth_year, "start_smoking_year" => start_smoking_year,
      "smoker_type" => smoker_type, "cigarettes_per_day" => cigarettes_per_day,
      "cigarette_nicotine_mg" => cigarette_nicotine_mg, "puffs_per_day" => puffs_per_day,
      "ecig_nicotine_mg" => ecig_nicotine_mg
    }
    new_values = profile_values.select { |_key, value| value.present? }
    errors = errors_for(new_values, current_data)
    new_values = new_values.except(*errors.keys)
    changed_values = new_values.select { |key, value| current_data[key] != value }
    updated_data = current_data.merge(changed_values)

    @chat.update!(profile_data: updated_data) if changed_values.present?

    missing = @chat.missing_fields(updated_data)
    unless @chat.done?
      @chat.update!(step: missing.empty? ? "awaiting_login" : "smoker")
    end

    { saved: changed_values, rejected: errors, profile: updated_data, missing: missing, complete: missing.empty? }
  end

  private

  def errors_for(values, current_data)
    errors = {}
    year = Date.current.year

    LIMITS.each do |field, range|
      next if values[field].nil?

      errors[field] = "must be between #{range.min} and #{range.max}" unless range.cover?(values[field].to_f)
    end

    birth_year = values["birth_year"] || current_data["birth_year"]
    start_year = values["start_smoking_year"] || current_data["start_smoking_year"]

    if values["birth_year"] && !((year - 120)..(year - 18)).cover?(birth_year.to_i)
      errors["birth_year"] = "the user must be between 18 and 120 years old"
    end

    errors["start_smoking_year"] = "cannot be in the future" if values["start_smoking_year"] && start_year.to_i > year
    if birth_year && start_year && start_year.to_i < birth_year.to_i
      errors["birth_year"] = "cannot be after the year the user started smoking" if values["birth_year"]
      errors["start_smoking_year"] = "cannot be before the year of birth" if values["start_smoking_year"]
    end

    errors
  end
end
