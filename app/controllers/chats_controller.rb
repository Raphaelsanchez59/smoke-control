class ChatsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[new create show]
  def new
    @chat = Chat.new
  end

  def create
    @chat = Chat.new(title: "My smoking profile")
    @chat.user = current_user
    if @chat.save
      flash[:chat_access] = true
      session[:chat_id] = @chat.id
      redirect_to chat_path(@chat)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @chat = Chat.find(params[:id])
    @message = Message.new
    return redirect_to new_chat_path unless access_allowed?
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
