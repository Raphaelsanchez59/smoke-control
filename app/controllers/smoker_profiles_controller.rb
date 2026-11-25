class SmokerProfilesController < ApplicationController
  before_action :set_smoker_profile, only: %i[show destroy]

  def show
  end

  def destroy
    @smoker_profile.destroy
    redirect_to root_path, status: :see_other
  end

  private

  def set_smoker_profile
    @smoker_profile = current_user.smoker_profiles.find(params[:id])
  end
end
