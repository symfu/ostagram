FactoryBot.define do
  factory :queue_image do
    association :client
    association :content
    association :style
    status { QueueImage::STATUS_NOT_PROCESSED }
    result { '' }
    ptime { nil }
    stime { Time.current }
    ftime { nil }
    end_status { QueueImage::STATUS_PROCESSED }
    likes_count { 0 }
    progress { 0.0 }
    
    trait :in_process do
      status { QueueImage::STATUS_IN_PROCESS }
      progress { 50.0 }
    end
    
    trait :processed do
      status { QueueImage::STATUS_PROCESSED }
      progress { 100.0 }
      ftime { Time.current }
      ptime { Time.current - 5.minutes }
    end
    
    trait :processed_by_bot do
      status { QueueImage::STATUS_PROCESSED_BY_BOT }
      progress { 100.0 }
      ftime { Time.current }
      ptime { Time.current - 10.minutes }
    end
    
    trait :error do
      status { QueueImage::STATUS_ERROR }
      progress { 0.0 }
    end
    
    trait :deleted do
      status { QueueImage::STATUS_DELETED }
    end
    
    trait :hidden do
      status { QueueImage::STATUS_HIDDEN }
    end
    
    trait :with_pimages do
      after(:create) do |queue_image|
        create_list(:pimage, 3, queue_image: queue_image)
      end
    end
    
    trait :with_likes do
      after(:create) do |queue_image|
        create_list(:like, 5, queue_image: queue_image)
        queue_image.update(likes_count: 5)
      end
    end
    
    trait :recent do
      created_at { 2.days.ago }
      ftime { 1.day.ago }
    end
    
    trait :old do
      created_at { 30.days.ago }
      ftime { 29.days.ago }
    end
  end
end
