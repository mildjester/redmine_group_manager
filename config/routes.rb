# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

#change_admin_group
#delete_admin_group

resources :gmanagers do
  member do
    get 'autocomplete_for_user'
  end
end

