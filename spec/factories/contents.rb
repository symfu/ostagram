FactoryBot.define do
  factory :content do
    image { File.open(Rails.root.join('spec', 'fixtures', 'test_content.jpg')) }
    status { 0 } # STATUS_HIDDEN
    
    trait :active do
      status { 1 } # STATUS_NOT_PROCESSED
    end
    
    trait :processed do
      status { 11 } # STATUS_PROCESSED
    end
    
    trait :error do
      status { -1 } # STATUS_ERROR
    end
    
    trait :deleted do
      status { -100 } # STATUS_DELETED
    end
    
    trait :with_queue_images do
      after(:create) do |content|
        create_list(:queue_image, 2, content: content)
      end
    end
  end
end
