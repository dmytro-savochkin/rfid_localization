Rfid::Application.routes.draw do
  match 'rr' => 'main#rr_graphs'

  root :to => 'main#algorithms'
end
