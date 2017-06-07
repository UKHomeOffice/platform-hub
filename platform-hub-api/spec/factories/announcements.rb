FactoryGirl.define do
  factory :announcement do
    id { SecureRandom.uuid }
    sequence :title do |n|
      "Announcement #{n}"
    end
    text do
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris ullamcorper erat orci, a imperdiet neque viverra laoreet. Nulla consequat nisl id sem dictum, sit amet scelerisque mauris faucibus. Nulla laoreet ligula eu ex tristique ornare. Mauris viverra dui varius libero gravida, ut lobortis ante fringilla. Quisque volutpat sit amet leo at vehicula. Quisque iaculis iaculis nibh, nec convallis mauris viverra eu. Proin gravida enim ut elit blandit rhoncus. Praesent ac est varius, mollis urna in, hendrerit dui.'
    end
    is_global false
    publish_at { DateTime.now.utc + 1.hour }

    factory :readonly_announcement do
      status :delivering
    end
  end
end
