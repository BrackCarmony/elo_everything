# Questions and categories come from the old Mongo dump: bin/rails elo:import
# Local demo account for trying the app (development only: the password is in this file).
if Rails.env.development?
  User.find_or_create_by!(email_address: "demo@example.com") do |user|
    user.display_name = "Demo Player"
    user.password = "elo-demo-1200"
  end
end
