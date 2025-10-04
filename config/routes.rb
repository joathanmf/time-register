require "sidekiq/web"

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :users do
        member do
          get :time_registers
          post :reports
        end
      end

      resources :time_registers
      resources :reports, only: [], param: :process_id do
        member do
          get :status
          get :download
        end
      end
    end
  end
end
