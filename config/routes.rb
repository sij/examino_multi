Rails.application.routes.draw do
  resources :owners
  resources :reports, only: [:index, :new]

  # evita pluralizzazione automatica controller: "data_analysis"
  resource :data_analysis, only: [], controller: "data_analysis" do
    get :input_analyze, as: :input_analyze
    get :res_analyze, as: :res_analyze     

    get :input_analyze_ter, as: :input_analyze_ter
    get :res_analyze_ter, as: :res_analyze_ter
  end

  resources :g1_details

    root "home#index"          # se vuoi che index sia la home
    get "about", to: "home#about"

  get 'home/select_point', to: 'home#select_point'
  post 'home/assign_point', to: 'home#assign_point'

  resources :points, only: [:index, :show]
  resources :roles

  resources :users do
    member do
      get :edit_my_password    # solo utente
      patch :update_my_password
      get :edit_password       # solo admin
      patch :update_password
    end
  end

  resource :session
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  get 'self_advances', to: 'home#self_advances', as: :self_advances

	 delete "/logout", to: "sessions#destroy", as: :logout	 

	 
	controller :menu do
		get :determine_menu
  end

  controller :snai_model do
    get :in_g1
    get :res_g1
  end  


  resources :get_data, only: [] do
    collection do
      get :show_csv, action: :show_csv, as: :show_csv     # mostra contenuto directory
      get  :in_get_g1       # mostra form
      get :res_get_g1      # esegue download + mostra lista
      post :res_get_g1      # esegue download + mostra lista
      post :update_csv
      post :update_all_csv
      post :delete_csv    # nuova rotta DELETE
    end
  end

end



