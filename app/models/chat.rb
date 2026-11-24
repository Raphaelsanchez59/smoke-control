class Chat < ApplicationRecord
  belongs_to :user, optional: true
  has_many :messages, dependent: :destroy

  STEPS = {
    # Début
    "smoker" => {
      question: "Es-tu fumeur ?",
      choices: { "Oui" => "birth", "Non" => "ex_smoker" }
    },
    "ex_smoker" => {
      question: "As-tu déjà été fumeur ?",
      choices: { "Oui" => "birth", "Non" => "never" }
    },
    "birth" => {
      question: "Quels sont ton mois et ton année de naissance ?",
      next: "start"
    },
    "start" => {
      question: "Quand as-tu commencé à fumer ? (approximativement)",
      next: "product"
    },
    "product" => {
      question: "Que fumes-tu ?",
      choices: {
        "Cigarettes" => "cig_brand",
        "Cigarette électronique" => "ecig_type",
        "Les deux" => "both_cig_brand"
      }
    },
    # --- Cigarettes seules ---
    "cig_brand" => {
      question: "Quelle marque de cigarette fumes-tu ?",
      next: "cig_per_day"
    },
    "cig_per_day" => {
      question: "Combien de cigarettes fumes-tu par jour ?",
      next: "done"
    },
    # --- Les deux : cigarettes, puis cigarette électronique ---
    "both_cig_brand" => {
      question: "Quelle marque de cigarette fumes-tu ?",
      next: "both_cig_per_day"
    },
    "both_cig_per_day" => {
      question: "Combien de cigarettes fumes-tu par jour ?",
      next: "ecig_type"
    },
    # --- Cigarette électronique ---
    "ecig_type" => {
      question: "Quel type de cigarette électronique ?",
      choices: { "Puff jetable" => "puff_nicotine", "Rechargeable" => "refill_nicotine" }
    },
    # Puff jetable
    "puff_nicotine" => {
      question: "Quel taux de nicotine ?",
      choices: { "0 mg/ml" => "puff_count", "10 mg/ml" => "puff_count", "20 mg/ml" => "puff_count" }
    },
    "puff_count" => {
      question: "Combien de bouffées annoncées sur ta puff ?",
      next: "puff_price"
    },
    "puff_price" => {
      question: "Combien coûte une puff (en €) ?",
      next: "puff_duration"
    },
    "puff_duration" => {
      question: "Combien de jours te dure une puff ? (ex : 10 à 14)",
      next: "done"
    },
    # Rechargeable
    "refill_nicotine" => {
      question: "Quel taux de nicotine dans ton e-liquide ?",
      choices: { "3 mg/ml" => "refill_ml", "6 mg/ml" => "refill_ml", "12 mg/ml" => "refill_ml",
                 "20 mg/ml" => "refill_ml" }
    },
    "refill_ml" => {
      question: "Combien de ml d'e-liquide utilises-tu par semaine ?",
      next: "refill_price"
    },
    "refill_price" => {
      question: "Combien coûte ton flacon de 10 ml (en €) ?",
      next: "done"
    },
    # Fins
    "never" => { question: "Bravo, tu n'as jamais fumé ! Ce coach ne te sera pas utile." },
    "done" => { question: "Merci ! Je calcule ton bilan nicotine…" }
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
