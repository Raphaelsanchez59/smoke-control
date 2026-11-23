class SmokerProfilesController < ApplicationController
  before_action :set_user, only %i[new create]

  def index
    @smokerprofiles = Smokerprofile.all
  end

  def show
    @smokerprofile = Smokerprofile.find(params[:id])
  end

  # def new
  #   @smokerprofile = Smokerprofile.new
  # end

  # def create
  #   @smokerprofile = Smokerprofile.new(params_smokerprofile)
  #   @smokerprofile.user = @user
  #   if @smokerprofile.save
  #     redirect_to smokerprofile_path(@smokerprofile)
  #   else
  #     render :new, status: :unprocessable_entity
  #   end
  # end

  # def destroy
  #   @smokerprofile = Smokerprofile.find(params[:id])
  #   @user = @smokerprofile.user

  # end

  # private

  # def set_user
  #   @user = User.find(params[:user_id])
  # end

  # def params_smokerprofile
  #   params.require(:smokerprofile).permit(:name, :cigarette_type, :user_id)
  # end

end
