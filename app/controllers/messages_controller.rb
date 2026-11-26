class MessagesController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  SYSTEM_PROMPT = <<~PROMPT
    You are Smokey, a friendly smoking cessation assistant with a taste for dark humor.
    Your goal: to build the user's smoking profile through natural conversation.
    You have access to a tool:
    - update_smoker_profile: to be activated as soon as the user provides one or more pieces of information
    (first name, age or year of birth, start date of smoking, type and quantity consumed).
    Only display what the user has actually said; never invent a value.
    The tool's output and the context below indicate any missing information:
    - if any information is missing, thank them briefly and then request it (maximum 2 at a time);
    - if the profile is complete, state it in one sentence and summarize it.
    Do not mention connection or analysis: the interface handles that.
    Do not offer any medical advice. Answer concisely.
  PROMPT

  before_action :set_chat

  def create
    @message = Message.new(role: "user", content: params.require(:message)[:content], chat: @chat)

    if @message.save
      @ruby_llm_chat = RubyLLM.chat
      build_conversation_history
      @ruby_llm_chat.with_tools(UpdateSmokerProfileTool.new(chat: @chat))

      response = @ruby_llm_chat.with_instructions(instructions).ask(@message.content)
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
      #{SYSTEM_PROMPT}
      Current year: #{Date.current.year}.
      Profile already registered: #{@chat.profile_data.to_json}
      Information still missing: #{missing.empty? ? 'none' : missing.join(', ')}
    TEXT
  end
end
