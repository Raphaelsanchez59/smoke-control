class ChatsController < ApplicationController
  def new
  end

  def create
    @chat = Chat.new(title: "Mon bilan nicotine")
    @chat.user = current_user
    if @chat.save
      redirect_to chat_path(@chat)
    else
      render :new, status: :unprocessable_entity
    end
  end
end
