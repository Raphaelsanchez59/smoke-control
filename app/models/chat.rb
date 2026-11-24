class Chat < ApplicationRecord
  belongs_to :user, optional: true
  has_many :messages, dependent: :destroy

  STEPS = {
    # Début
    "smoker" => {
      question: "Are you a smoker ?",
      choices: { "Yes" => "birth", "No" => "ex_smoker" }
    },
    "ex_smoker" => {
      question: "Did you ever smoke ?",
      choices: { "Yes" => "birth", "No" => "never" }
    },
    "birth" => {
      question: "When were you born ?",
      next: "start"
    },
    "start" => {
      question: "When did you start smoking ? (approximately)",
      next: "product"
    },
    "product" => {
      question: "What do you smoke ?",
      choices: {
        "Cigarets" => "cig_brand",
        "Electronic cigaret" => "ecig_type",
        "Both" => "both_cig_brand"
      }
    },
    # --- Cigarettes seules ---
    "cig_brand" => {
      question: "Which brand do you smoke ?",
      next: "cig_per_day"
    },
    "cig_per_day" => {
      question: "How many cigarets per day ?",
      next: "done"
    },
    # --- Les deux : cigarettes, puis cigarette électronique ---
    "both_cig_brand" => {
      question: "Which brand do you smoke ?",
      next: "both_cig_per_day"
    },
    "both_cig_per_day" => {
      question: "How many cigarets per day ?",
      next: "ecig_type"
    },
    # --- Cigarette électronique ---
    "ecig_type" => {
      question: "Which type of electronic cigaret do you smoke ?",
      choices: { "Disposable vape" => "puff_nicotine", "Rechargeable" => "refill_nicotine" }
    },
    # Puff jetable
    "puff_nicotine" => {
      question: "What nicotine level ?",
      choices: { "0 mg/ml" => "puff_count", "10 mg/ml" => "puff_count", "20 mg/ml" => "puff_count" }
    },
    "puff_count" => {
      question: "How many puffs is your disposable vape advertised to have ?",
      next: "puff_price"
    },
    "puff_price" => {
      question: "How much does a disposable vape cost (in €) ?",
      next: "puff_duration"
    },
    "puff_duration" => {
      question: "How many days does a disposable vape (puff) last you ? (ex: 10 to 14) ",
      next: "done"
    },
    # Rechargeable
    "refill_nicotine" => {
      question: "Quel taux de nicotine dans ton e-liquide ?",
      choices: { "3 mg/ml" => "refill_ml", "6 mg/ml" => "refill_ml", "12 mg/ml" => "refill_ml",
                 "20 mg/ml" => "refill_ml" }
    },
    "refill_ml" => {
      question: "What is the nicotine level in your e-liquid ?",
      next: "refill_price"
    },
    "refill_price" => {
      question: "How much does your 10 ml bottle cost (in €) ?",
      next: "done"
    },
    # Fins
    "never" => { question: "Well done—you’ve never smoked! This coach won’t be of any use to you." },
    "done" => { question: "Thanks! I’m calculating your smoker profile…" }
  }

  # L'étape en cours (question + choix ou next)
  def current_step
    STEPS[step]
  end

  # Le coach pose la question de l'étape en cours
  def start
    messages.create!(role: "assistant", content: current_step[:question])
  end

  # Enregistre la réponse, passe à l'étape suivante, pose la question suivante
  def answer(text)
    messages.create!(role: "user", content: text)
    next_step = current_step[:choices] ? current_step[:choices][text] : current_step[:next]
    update!(step: next_step)
    messages.create!(role: "assistant", content: current_step[:question])
  end

  # Plus de question après : fin de conversation
  def finished?
    current_step[:choices].nil? && current_step[:next].nil?
  end
end
