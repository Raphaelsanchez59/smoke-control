class MessagesController < ApplicationController
  skip_before_action :authenticate_user!, only: :create

  def create
    @chat = Chat.find(params[:chat_id])
    return redirect_to new_chat_path unless can_answer?

    content = message_params[:content]
    if !@chat.finished? && content.present?
      @chat.answer(content)
      @chat.generate_report if @chat.step == "done"
    end

    flash[:chat_access] = true
    redirect_to chat_path(@chat)
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end

  def can_answer?
    if user_signed_in?
      @chat.user == current_user
    else
      session[:chat_id] == @chat.id
    end
  end
end
