Rails.application.routes.draw do
  root :to => 'agile_application#agile_process_default_request'

  Agile.routes

end
