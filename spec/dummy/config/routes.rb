Rails.application.routes.draw do

  mount Exportable::Engine => "/exportable"
end
