FactoryGirl.define do
  factory :docs_source_entry do
    docs_source

    sequence :content_id do |n|
      "#{n}"
    end

    sequence :content_url do |n|
      "http://example.com/#{n}"
    end
  end
end
