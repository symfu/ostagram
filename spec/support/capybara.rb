RSpec.configure do |config|
  config.before(:each, type: :feature) do
    Capybara.default_driver = :rack_test
  end

  config.before(:each, type: :feature, js: true) do
    Capybara.default_driver = :selenium
  end

  config.after(:each, type: :feature) do
    Capybara.use_default_driver
  end
end

Capybara.configure do |config|
  config.default_max_wait_time = 5
  config.server = :puma, { Silent: true }
end
