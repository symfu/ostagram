FactoryBot.define do
  factory :style do
    image { File.open(Rails.root.join('spec', 'fixtures', 'test_style.jpg')) }
    init { 'starry_night' }
    status { QueueImage::STATUS_HIDDEN }
    use_counter { 0 }
    
    trait :active do
      status { QueueImage::STATUS_NOT_PROCESSED }
    end
    
    trait :processed do
      status { QueueImage::STATUS_PROCESSED }
    end
    
    trait :popular do
      use_counter { 100 }
    end
    
    trait :with_queue_images do
      after(:create) do |style|
        create_list(:queue_image, 3, style: style)
      end
    end
  end
end
