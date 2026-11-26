class ChatsController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  GREETING = "Hello, I'm Smokey, your smoking assistant. We're going to create your smoker profile. " \
             "I'll need some information: your first name, your age, how long you've been smoking, " \
             "your consumption…".freeze

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

  def show
    @chat = Chat.find(params[:id])
    @messages = @chat.messages.order(:created_at)
    @message  = Message.new

    return unless user_signed_in? && @chat.user == current_user

    @profile = if @chat.awaiting_login?
                 @chat.save_data_profile!(current_user)
               elsif @chat.done?
                 current_user.smoker_profiles.order(:created_at).last
               end
  end

  def create
    @chat = Chat.new(title: "My smoking profile", user: current_user)
    @chat.save!
    Message.create!(role: "assistant", content: GREETING, chat: @chat)
    @message = Message.new(role: "user", content: params[:message]["content"], chat: @chat)

    if @message.save
      @ruby_llm_chat = RubyLLM.chat
      build_conversation_history
      @ruby_llm_chat.with_tools(UpdateSmokerProfileTool.new(chat: @chat))

      response = @ruby_llm_chat.with_instructions(instructions).ask(@message.content)
      Message.create!(role: "assistant", content: response.content, chat: @chat)

      @chat.save_data_profile!(current_user) if @chat.awaiting_login? && user_signed_in?
      session[:chat_id] = @chat.id unless user_signed_in?

      redirect_to chat_path(@chat)
    else
      render "chats/show", status: :unprocessable_entity
    end
  end

  private

  def build_conversation_history
    @chat.messages.order(:created_at).each do |message|
      next if message.content.blank?

      @ruby_llm_chat.add_message(role: message.role, content: message.content)
    end
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
