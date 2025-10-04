Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :users do
        get 'time_registers', on: :member
      end

      resources :time_registers
    end
  end
end
