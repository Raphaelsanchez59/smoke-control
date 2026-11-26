class MessagesController < ApplicationController
  skip_before_action :authenticate_user!

  FOLLOWUP_PROMPT = <<~PROMPT
    You are Smokey, a friendly smoking cessation assistant with a taste for dark humor.
    The user's smoker profile is already complete. Chat freely with them about it:
    their consumption, costs, health impact and how to cut down or quit.
    Base your answers on the profile below and never invent values.
    Do not ask for profile information again.
    Do not offer any medical advice. Answer in English, concisely (120 words maximum).
  PROMPT

  before_action :set_chat

  def create
    @message = Message.new(role: "user", content: params.require(:message)[:content], chat: @chat)

    if @message.save
      @ruby_llm_chat = RubyLLM.chat
      build_conversation_history

      if @chat.done?
        response = @ruby_llm_chat.with_instructions(followup_instructions).ask(@message.content)
      else
        @ruby_llm_chat.with_tools(UpdateSmokerProfileTool.new(chat: @chat))
        response = @ruby_llm_chat.with_instructions(instructions).ask(@message.content)
      end
      Message.create!(role: "assistant", content: response.content, chat: @chat)

      @profile = @chat.save_data_profile!(current_user) if @chat.awaiting_login? && user_signed_in?

      redirect_to chat_path(@chat)
    else
      @messages = @chat.messages.order(:created_at)
      render "chats/show", status: :unprocessable_entity
    end
  end

  private

  def user_message_limit
    return unless chat.messages.where(role: "user").count >= MAX_USER_MESSAGES

    errors.add(:content, "You can only send #{MAX_USER_MESSAGES} messages per chat.")
  end

  def build_conversation_history
    @chat.messages.where.not(id: @message.id).order(:created_at).each do |message|
      next if message.content.blank?

      @ruby_llm_chat.add_message(role: message.role, content: message.content)
    end
  end

  def set_chat
    @chat = Chat.find(params[:chat_id])
  end

  def instructions
    missing = @chat.missing_fields

    <<~TEXT
      #{Chat::COLLECT_PROMPT}
      Current year: #{Date.current.year}.
      Profile already registered: #{@chat.profile_data.to_json}
      Information still missing: #{missing.empty? ? 'none' : missing.join(', ')}
    TEXT
  end

  def followup_instructions
    profile = @chat.user&.smoker_profiles&.order(:created_at)&.last
    details = profile&.attributes&.slice("name", "cigarette_type", "years_to_live", "content")

    <<~TEXT
      #{FOLLOWUP_PROMPT}
      Current year: #{Date.current.year}.
      Smoker profile: #{details.to_json}
    TEXT
  end
end
