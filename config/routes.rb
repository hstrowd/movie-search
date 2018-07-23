# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  namespace :api do
    jsonapi_resources :movies, only: %i[index show] do
      jsonapi_relationships only: :show
    end
    jsonapi_resources :cast_members, only: %i[show] do
      jsonapi_relationships only: :show
    end
    jsonapi_resources :creators, only: %i[show] do
      jsonapi_relationships only: :show
    end
    jsonapi_resources :directors, only: %i[show] do
      jsonapi_relationships only: :show
    end
    jsonapi_resources :genres, only: %i[show] do
      jsonapi_relationships only: :show
    end
    jsonapi_resources :keywords, only: %i[show] do
      jsonapi_relationships only: :show
    end
  end
end
