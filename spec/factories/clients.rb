FactoryBot.define do
  factory :client do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:name) { |n| "User#{n}" }
    avatar { File.open(Rails.root.join('spec', 'fixtures', 'test_avatar.jpg')) }
    password { 'password123' }
    password_confirmation { 'password123' }
    role_id { Client::CLIENT_TYPE_USER }
    
    trait :admin do
      role_id { Client::CLIENT_TYPE_ADMIN }
    end
    
    trait :confirmed do
      confirmed_at { Time.current }
    end
    
    trait :locked do
      locked_at { Time.current }
      failed_attempts { 5 }
    end
    
    trait :with_queue_images do
      after(:create) do |client|
        create_list(:queue_image, 3, client: client)
      end
    end
    
    trait :with_likes do
      after(:create) do |client|
        create_list(:like, 2, client: client)
      end
    end
  end
end
