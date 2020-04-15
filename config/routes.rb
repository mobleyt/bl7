Rails.application.routes.default_url_options[:script_name] = '/lcdl'
Rails.application.routes.draw do

  concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new
  mount Blacklight::Engine => '/'
  mount BlacklightAdvancedSearch::Engine => '/'

  root to: "catalog#index"
  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
    concerns :range_searchable
  end

  devise_for :users, :skip => [:registrations] 
  as :user do
    get 'users/edit' => 'devise/registrations#edit', :as => 'edit_user_registration'
    put 'users' => 'devise/registrations#update', :as => 'user_registration'
  end

  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  get 'collections/compound', to: 'collections#compound_manifest'
  get 'collections/multi', to: 'collections#multi_manifest'
  get 'collections/fulltext', to: 'collections#iiif_fulltext'
  get 'collections/annotation', to: 'collections#other_manifest'

  get 'viewer', to: 'viewer#index'

  post 'exclude', to: 'catalog#session_pages'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
