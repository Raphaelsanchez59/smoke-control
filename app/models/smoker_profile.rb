class SmokerProfile < ApplicationRecord
  CIGARETTE_TYPES = ["cigarette", "e_cigarette", "both"]
  belongs_to :user
  belongs_to :chat, optional: true
  has_many :cigarettes, dependent: :destroy
  has_many :e_cigarettes, dependent: :destroy

  validates :cigarette_type, inclusion: { in: CIGARETTE_TYPES }, allow_blank: true
  validates :name, length: { maximum: 100 }, allow_blank: true
  validates :years_to_live,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 120 },
            allow_nil: true
  validates :content, length: { maximum: 5000 }, allow_blank: true

  def generate_profile! # rubocop:disable Metrics/MethodLength,Metrics/PerceivedComplexity
    cigarette   = cigarettes.last
    e_cigarette = e_cigarettes.last

    prompt = <<~PROMPT
      Smoker profile:
       - First name : #{name}
       - Year of birth: #{user.birth_date&.year || 'unknown'}
       - Smokes since: #{user.start_smoking_year || 'unknown'}
       - Type : #{cigarette_type}
       - Cigarettes per day: #{cigarette&.quantity_by_day || 'none'}
       - E-cigarette puffs per day:#{e_cigarette&.puff_by_day || 'none'}

       Current year: #{Date.current.year}.
       Provide an indicative estimate of this person's remaining life expectancy (in years, whole number) and write a short analytical paragraph in English (maximum 4 sentences). Specify that this is an indicative estimate and not medical advice.
       Generate a short, darkly humorous using the estimated age at the end of life (current age + years_to_live) as an uncertain joke, never as a prediction or deadline. Avoid generic labels. Example: "Smokey is aiming for the XX year mark". If the age or estimate is unavailable, do not invent a number, include it in the JSON response
       Respond ONLY with a JSON object. {"years_to_live": <integer>, "analysis": "<text>", "title": "<text>"}
    PROMPT

    data = JSON.parse(RubyLLM.chat.ask(prompt).content[/\{.*\}/m])
    update!(years_to_live: data["years_to_live"], content: data["analysis"], name: data["title"])
  rescue JSON::ParserError, TypeError, RubyLLM::Error => e
    Rails.logger.error("[Smokey] analyse impossible : #{e.message}")
  end

  def photo_asset
    case cigarette_type.to_s.downcase
    when "e_cigarette", "ecigarette", "e-cigarette", "vape"
      "ecigarette.jpg"
    when "both", "cigarette_and_e_cigarette"
      "ecigarette-cigarette.jpg"
    else
      "cigarette.jpg"
    end
  end
end
