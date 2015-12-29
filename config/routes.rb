Rails.application.routes.draw do
  resources :styles
  match '/styles/:id/mark', to: 'styles#mark', via: 'put'

  resources :contents
  get 'admin_pages/main'
  get 'admin_pages/images'
  get 'admin_pages/users'
  get 'admin_pages/startbot'
  get 'admin_pages/startprocess'
  get 'admin_pages/unregworkers'
  get 'admin_pages/update_queue_status'
  match '/admin_pages/update_queue_status', to: 'admin_pages#update_queue_status', via: 'put'
  match '/admin_pages/update_style_status', to: 'admin_pages#update_style_status', via: 'put'
  match '/admin_pages/update_content_status', to: 'admin_pages#update_content_status', via: 'put'
  match '/admin_pages/delete_queue', to: 'admin_pages#delete_queue', via: 'put'

  devise_for :clients
  resources :queue_images
  match '/queue_images/:id/visible', to: 'queue_images#visible', via: 'put'
  match '/queue_images/:id/hidden', to: 'queue_images#hidden', via: 'put'
  match '/queue_images/:id/like', to: 'queue_images#like_image', via: 'put'
  match '/queue_images/:id/unlike', to: 'queue_images#unlike_image', via: 'put'

  get 'static_pages/lenta', as: 'user_root'

  match '/about', to: 'static_pages#about', via: 'get'
  match '/home', to: 'static_pages#home', via: 'get'
  match '/error', to: 'static_pages#error', via: 'get'
  match '/lenta', to: 'static_pages#lenta', via: 'get'

  root "static_pages#home"
end
