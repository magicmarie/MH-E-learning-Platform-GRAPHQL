Rails.application.routes.draw do
  resources :courses
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  require "sidekiq/web"

  if Rails.env.development? || Rails.env.test?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
    mount Sidekiq::Web => "/sidekiq"
  elsif Rails.env.production?
    Sidekiq::Web.use Rack::Auth::Basic, "Protected Area" do |username, password|
      ActiveSupport::SecurityUtils.secure_compare(username, ENV["SIDEKIQ_USER"]) &
        ActiveSupport::SecurityUtils.secure_compare(password, ENV["SIDEKIQ_PASSWORD"])
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check

  # Auth
  post "/signup", to: "auth#signup"
  post "/login", to: "auth#login"
  post "/login/security", to: "auth#verify_security"

  # organizations -- all users
  resources :organizations, only: [ :index ] do
    collection do
      get :search
    end
  end

  # -- Org admin
  resource :organization, only: [ :show, :update ]
  # GET /organization
  # PATCH /organization

  # Password Reset
  post "/password/change", to: "auth#change_password"
  post "/request_password_reset", to: "passwords#create"
  put "/reset_password", to: "passwords#update"

  resources :user_profiles, only: [ :show, :update ]
  # GET /user_profiles/:id
  # PATCH /user_profiles/:id

  resources :students, only: [ :index, :show ]
  # GET /students
  # GET /students/:id

  concern :user_routes do
    member do
      patch :activate # PATCH /users/:id/activate
      patch :deactivate # PATCH /users/:id/deactivate
      get :organization # GET /users/:id/organization
      post :bulk_create # POST /users/:id/bulk_create
    end

    collection do
      post :bulk_create
    end
  end

  resources :users, only: [ :create, :index, :update, :destroy ], concerns: :user_routes
  # GET /users
  # POST /users
  # PATCH /users/:id
  # DELETE /users/:id
  # user_member_actions urls too

  # Global Admin
  namespace :admin do
    get "organizations/stats", to: "organizations#index_stats" # GET /admin/organizations/stats

    resources :organizations, only: [ :index, :create, :show, :update, :destroy ]
    # POST /admin/organizations
    # GET /admin/organizations/:id
    # PATCH /admin/organizations/:id
    # DELETE /admin/organizations/:id

    resources :users, only: [ :create, :index, :update, :destroy ], concerns: :user_routes
    # GET /admin/users
    # POST /admin/users
    # PATCH /admin/users/:id
    # DELETE /admin/users/:id
    # user_member_actions urls too, add admin before users.
  end

  # Global Admin || Org Admin || Teacher
  resources :courses do
    # GET /courses
    # POST /courses
    # GET /courses/:id
    # PATCH /courses/:id
    # DELETE /courses/:id

    get "students/enrolled", to: "students#enrolled"
    get "students/unenrolled", to: "students#unenrolled"
    post "enrollments/bulk", to: "enrollments#bulk_create"

    resources :resources, only: [ :index, :create, :update, :destroy, :show ]
    # GET /courses/:course_id/resources
    # GET /courses/:course_id/resources/:id
    # POST /courses/:course_id/resources
    # PATCH /courses/:course_id/resources/:id
    # DELETE /courses/:course_id/resources/:id

    resources :enrollments, only: [ :index, :create, :update, :destroy, :show ]
    # GET /courses/:course_id/enrollments
    # GET /courses/:course_id/enrollments/:id
    # POST /courses/:course_id/enrollments
    # PATCH /courses/:course_id/enrollments/:id
    # DELETE /courses/:course_id/enrollments/:id

    resources :assignments, only: [ :index, :create, :update, :destroy, :show ]
    # GET /courses/:course_id/assignments
    # GET /courses/:course_id/assignments/:id
    # POST /courses/:course_id/assignments
    # PATCH /courses/:course_id/assignments/:id
    # DELETE /courses/:course_id/assignments/:id

    resources :assessments, only: [ :index, :create, :update, :show ]
    # GET /courses/:course_id/assessments
    # POST /courses/:course_id/assessments
    # GET /courses/:course_id/assessments/:id
    # PATCH /courses/:course_id/assessments/:id
  end
end
