Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resource :registration, only: %i[new create]

  resources :categories, only: %i[index show] do
    # The quiz: show the next question, then score the answer.
    resource :play, only: :show, controller: "plays"
    resources :answers, only: :create
  end
  resources :attempts, only: :show
  resource :profile, only: :show

  get "up" => "rails/health#show", as: :rails_health_check

  root "categories#index"
end
