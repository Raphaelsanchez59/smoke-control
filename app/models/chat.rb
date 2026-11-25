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
      question: "When were you born ? (MM/YYYY)",
      next: "start"
    },
    "start" => {
      question: "When did you start smoking ? (approximately - MM/YYYY))",
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
      question: "Which cigarets brand do you smoke ?",
      next: "cig_per_day"
    },
    "cig_per_day" => {
      question: "How many cigarets per day ?",
      next: "done"
    },
    # --- Les deux : cigarettes, puis cigarette électronique ---
    "both_cig_brand" => {
      question: "Which cigarets brand do you smoke ?",
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
      question: "What is the nicotine level in your e-liquid ?",
      choices: { "3 mg/ml" => "refill_ml", "6 mg/ml" => "refill_ml", "12 mg/ml" => "refill_ml",
                 "20 mg/ml" => "refill_ml" }
    },
    "refill_ml" => {
      question: "How many ml of e-liquid do you use per week ?",
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

  SYSTEM_PROMPT = <<~PROMPT
    You are the coach of Smoke Control, an app that helps people become aware of their nicotine consumption.

    The conversation has two phases.

    PHASE 1 – The report (your first message)
    The first user message contains the user's answers to a questionnaire (Question → Answer).
    Write their personal nicotine report.
    If an answer is missing or unclear, make a reasonable estimate and mark it "(estimated)".

    Calculate and present:
      1. Daily nicotine intake (mg).
        - Cigarettes: recognise the brand and variety written freely, even with typos
          (e.g. "malboro red" = Marlboro Red), and estimate nicotine per cigarette.
        - Disposable vape: nicotine (mg/ml) and advertised number of puffs.
          A duration like "10 to 14 days" means an average of 12 days.
      2. The current price of their pack of cigarettes in France, and how it has changed
         since they started smoking, if they smoke cigarettes.
      3. Their cost per month (30 days) and per year (365 days), in euros.
      4. How many years they have been smoking, and the total amount spent since they started.
      5. Estimated life lost. Convert it into days and years.

    Report format: Markdown, short headings, bullet lists, key numbers in bold, 250 words maximum.
    End the report with one short, darkly humorous line in the spirit of
    "Congratulations, here's the life you've lost:" followed by the life-lost total
    and a playful comparison (films you could have watched, trips you could have paid for, etc.).
    The humour targets the cigarette, never the person: no shaming, no insults.

    PHASE 2 – The conversation (every message after the report)
    The user may ask follow-up questions or correct an answer.
    - Answer in 120 words maximum, based on their answers and your report.
    - If they correct an answer, recalculate only what changes.
    - Stay on topic: smoking, vaping, nicotine, cost, health impact, quitting.
      If they go off topic, kindly bring them back.
    - Ask at most one question per message.

    Rules for both phases:
    - Always answer in English, in a friendly and casual tone.
    - Mark every value you estimate (nicotine, price) with "(estimated)".
    - Show each calculation on one line (e.g. 15 cig/day × €0.65 = €9.75/day).
    - Never give a medical diagnosis or treatment advice.
    - If the user wants to quit, encourage them and mention that
      Tabac Info Service (39 89, free, in France) can help.
  PROMPT
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

  def answers_for_ai
    messages.order(:created_at).map { |m| "#{m.role == 'user' ? 'Answer' : 'Question'}: #{m.content}" }.join("\n")
  end

  def generate_report
    response = RubyLLM.chat.with_instructions(SYSTEM_PROMPT).ask(answers_for_ai)
    messages.create!(role: "assistant", content: response.content)
  end
end
