RSpec.configure do |config|
  config.before(:each) do
    ActionMailer::Base.default_url_options = { host: 'localhost', port: 3000 }
  end
end
