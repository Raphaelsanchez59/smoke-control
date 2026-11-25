class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: :home

  def home
    @smoker_profiles = if user_signed_in?
                         current_user.smoker_profiles
                                     .includes(:cigarettes, :e_cigarettes)
                                     .order(Arel.sql("years_to_live DESC NULLS LAST"))
                       else
                         SmokerProfile.none
                       end
  end
end
