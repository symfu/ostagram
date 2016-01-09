FactoryBot.define do
  factory :like do
    association :client
    association :queue_image
    
    trait :recent do
      created_at { 1.hour.ago }
    end
    
    trait :old do
      created_at { 1.week.ago }
    end
  end
end
