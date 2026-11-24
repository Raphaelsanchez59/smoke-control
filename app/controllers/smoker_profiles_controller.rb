class SmokerProfilesController < ApplicationController
  def show
    @smokerprofile = SmokerProfile.find(params[:id])
  end

  def destroy
    @smokerprofile = Smokerprofile.find(params[:id])
    @user = @smokerprofile.user
    @smokerprofile.destroy

    redirect_to root_path, status: :see_other
  end
end
