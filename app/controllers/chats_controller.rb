class ChatsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[new create show home_question]
  def new
    @chat = Chat.new
  end

  def create
    @chat = Chat.new(title: "My smoking profile")
    @chat.user = current_user
    @chat.step = params[:from_step] if Chat::STEPS.key?(params[:from_step])
    if @chat.save
      @chat.start
      @chat.answer(params[:answer]) if params[:answer].present?
      flash[:chat_access] = true
      session[:chat_id] = @chat.id
      redirect_to chat_path(@chat)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @chat = Chat.find(params[:id])
    return redirect_to new_chat_path unless access_allowed?

    @messages = @chat.messages.order(:created_at)
    @message = Message.new
    render :new
  end

  def home_question # renvoi les question de la page d'accueil dans le chat
    step = %w[smoker ex_smoker never].include?(params[:step]) ? params[:step] : "smoker"
    render partial: "chats/home_question", locals: { step: step }
  end

  private

  def access_allowed?
    if user_signed_in?
      @chat.user == current_user
    else
      flash[:chat_access] && session[:chat_id] == @chat.id
    end
  end
end
