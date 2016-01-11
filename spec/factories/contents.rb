FactoryBot.define do
  factory :content do
    image { File.open(Rails.root.join('spec', 'fixtures', 'test_content.jpg')) }
    status { QueueImage::STATUS_HIDDEN }
    
    trait :active do
      status { QueueImage::STATUS_NOT_PROCESSED }
    end
    
    trait :processed do
      status { QueueImage::STATUS_PROCESSED }
    end
    
    trait :error do
      status { QueueImage::STATUS_ERROR }
    end
    
    trait :deleted do
      status { QueueImage::STATUS_DELETED }
    end
    
    trait :with_queue_images do
      after(:create) do |content|
        create_list(:queue_image, 2, content: content)
      end
    end
  end
end
