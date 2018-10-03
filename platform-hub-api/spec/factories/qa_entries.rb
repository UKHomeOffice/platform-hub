FactoryGirl.define do
  factory :qa_entry do
    sequence :question do |n|
      "Q#{n}"
    end
    sequence :answer do |n|
      "Answer for Q#{n}"
    end
  end
end
