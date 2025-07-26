Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  root "dashboard#index"

  get "up" => "rails/health#show", as: :rails_health_check
  get 'dashboard', to: 'dashboard#index', as: 'dashboard'
  get 'dashboard/monthly_overview', to: 'dashboard#monthly_overview', as: 'monthly_overview'

  resources :budgets do
    collection do
      post :copy_yearly_budgets
      get :import_form
      post :import
      post :import_preview
    end
  end

  resources :goals do
    member do
      patch :archive
      patch :unarchive
    end
  end

  resources :categories do
    resources :subcategories, controller: 'categories'
  end
  get 'categories/:id/destroy', to: 'categories#destroy_confirm', as: 'destroy_category'

  resources :transactions do
    collection do
      get :import_form
      post :import
      post :import_preview
    end
  end

  resources :loans
  
  resources :loan_payments
end