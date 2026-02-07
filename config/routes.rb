Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  root 'dashboard#index'

  get 'up' => 'rails/health#show', :as => :rails_health_check
  get 'metrics' => 'metrics#index', :as => :metrics
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
    member do
      get :average_spending
    end
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

  namespace :tools do
    get "import-export", to: "import_exports#show", as: :import_export
    post "import-export/export", to: "import_exports#export", as: :import_export_export
    post "import-export/import", to: "import_exports#import", as: :import_export_import
  end

  get "tools/amortization", to: "tools/calculators#amortization", as: "amortization_calculator"
  get "tools/investment", to: "tools/calculators#investment", as: "investment_calculator"
end
