class ChatsController < ApplicationController
  skip_before_action :authenticate_user!

  GREETING = <<~TEXT.freeze
    Hello, I'm Smokey, your smoking cessation assistant.

    Let's build your smoker profile together.

    To get started, please tell me:
    - Your name
    - Your age
    - When you started smoking
    - What you use: cigarettes, e-cigarette, or both
    - Your daily consumption (cigarettes per day and/or puffs per day)
  TEXT

  def show
    @chat = Chat.find(params[:id])
    @messages = @chat.messages.order(:created_at)
    @message  = Message.new

    return unless user_signed_in? && @chat.user == current_user

    @profile = if @chat.awaiting_login?
                 @chat.save_data_profile!(current_user)
               elsif @chat.done?
                   @chat.smoker_profile
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
                    .with_tool_options(choice: :required, calls: :one)

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
      #{Chat::COLLECT_PROMPT}
      Current year: #{Date.current.year}.
      Profile already registered: #{@chat.profile_data.to_json}
      Information still missing: #{missing.empty? ? 'none' : missing.join(', ')}
    TEXT
  end
end
