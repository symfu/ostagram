FactoryBot.define do
  factory :pimage do
    association :queue_image
    iterate { 1 }
    imageurl { File.open(Rails.root.join('spec', 'fixtures', 'test_pimage.jpg')) }
    
    trait :first_iteration do
      iterate { 1 }
    end
    
    trait :second_iteration do
      iterate { 2 }
    end
    
    trait :final_iteration do
      iterate { 10 }
    end
    
    trait :recent do
      created_at { 1.hour.ago }
    end
    
    trait :old do
      created_at { 1.week.ago }
    end
  end
end
