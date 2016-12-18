Airbrake.configure do |config|
  config.host = 'http://error.pooul.cn'
  config.project_id = 1 # required, but any positive integer works
  config.project_key = 'ed73f1d1c8cfdafa89638b844fb73121'

  # Uncomment for Rails apps
  config.environment = Rails.env
  config.ignore_environments = %w(development test)
end
