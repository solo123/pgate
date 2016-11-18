Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  post 'pay', to: 'payments#pay'
  post 'query', to: 'query#qry'
  match 'notify/:ref/:sender', to: 'notify_recvs#notify', as: :notify, via: :all
  match 'callback/:ref/:sender', to: 'notify_recvs#callback', as: :callback, via: :all
end
