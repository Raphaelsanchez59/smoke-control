class SmokerProfilesController < ApplicationController
  def show
    @smokerprofile = SmokerProfile.find(params[:id])
  end

  def destroy
    @smokerprofile = Smokerprofile.find(params[:id])
    @user = @smokerprofile.user
  end
end
