# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# frozen_string_literal: true

puts "Seeding smoker profiles..."

user = User.first || User.create!(
  email: "guillaume@smokecontrol.test",
  nickname: "Guillaume",
  birth_date: Date.new(1991, 5, 14),
  start_smoking_year: Date.current.year - 10,
  password: "Password123!",
  password_confirmation: "Password123!"
)

user = User.first || User.create!(
  email: "guillaume@smokecontrol.test",
  nickname: "Guillaume",
  birth_date: Date.new(1991, 5, 14),
  start_smoking_year: Date.current.year - 10,
  password: "Password123!",
  password_confirmation: "Password123!"
)

puts "Cleaning smoker profiles and dependencies for #{user.email}..."
SmokerProfile.where(user: user).destroy_all

age = if user.respond_to?(:birth_date) && user.birth_date.present?
        today = Date.current
        today.year - user.birth_date.year - ((today.month > user.birth_date.month || (today.month == user.birth_date.month && today.day >= user.birth_date.day)) ? 0 : 1)
      else
        35
      end

years_smoking = if user.respond_to?(:start_smoking_year) && user.start_smoking_year.present?
                  [Date.current.year - user.start_smoking_year.to_i, 1].max
                else
                  10
                end

profiles_data = [
  {
    name: "Marlboro Red",
    cigarette_type: "cigarette",
    years_to_live: 30,
    image: nil,
    cigarette: {
      quantity_by_day: 15,
      nicotine_mg: 0.8
    },
    summary_builder: ->(years_to_live, cig, _ecig) do
      "At #{age}, with a smoking habit of #{cig[:quantity_by_day]} cigarettes a day for the past #{years_smoking} years, your life expectancy is #{years_to_live} years. You've already completed half your journey!!"
    end
  },
  {
    name: "E-Cigarette",
    cigarette_type: "e_cigarette",
    years_to_live: 50,
    image: nil,
    e_cigarette: {
      puff_by_day: 150,
      nicotine_mg: 10.0
    },
    summary_builder: ->(years_to_live, _cig, ecig) do
      "At #{age} years old, with a consumption of #{ecig[:puff_by_day]} puffs per day for the past #{years_smoking} years, your life expectancy is #{years_to_live} years. If you want to go further, cut down!"
    end
  },
  {
    name: "Mixed Habit",
    cigarette_type: "both",
    years_to_live: 40,
    image: nil,
    cigarette: {
      quantity_by_day: 8,
      nicotine_mg: 0.6
    },
    e_cigarette: {
      puff_by_day: 150,
      nicotine_mg: 6.0
    },
    summary_builder: ->(years_to_live, cig, ecig) do
      "At #{age} years old, with #{cig[:quantity_by_day]} cigarettes and #{ecig[:puff_by_day]} puffs per day for the past #{years_smoking} years, your life expectancy is #{years_to_live} years. If you want to have more time, just stop!"
    end
  }
]

profiles_data.each do |profile_attrs|
  content_text = profile_attrs[:summary_builder].call(
    profile_attrs[:years_to_live],
    profile_attrs[:cigarette],
    profile_attrs[:e_cigarette]
  )

  smoker_profile = SmokerProfile.find_or_initialize_by(
    user: user,
    name: profile_attrs[:name]
  )

  smoker_profile.update!(
    cigarette_type: profile_attrs[:cigarette_type],
    years_to_live: profile_attrs[:years_to_live],
    content: content_text,
    image: profile_attrs[:image]
  )

  if profile_attrs[:cigarette]
    cig = Cigarette.find_or_initialize_by(smoker_profile: smoker_profile)
    cig.update!(profile_attrs[:cigarette])
  end

  if profile_attrs[:e_cigarette]
    ecig = ECigarette.find_or_initialize_by(smoker_profile: smoker_profile)
    ecig.update!(profile_attrs[:e_cigarette])
  end
end

puts "Done! #{user.smoker_profiles.count} smoker profiles attached to #{user.email}."