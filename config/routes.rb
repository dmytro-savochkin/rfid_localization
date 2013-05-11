Rfid::Application.routes.draw do
  match 'rr_graphs' => 'welcome#rr_graphs'

  root :to => 'welcome#index'
end
