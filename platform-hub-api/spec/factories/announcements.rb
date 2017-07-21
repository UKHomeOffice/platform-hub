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
    publish_at { 1.hour.from_now }

    factory :readonly_announcement do
      status :delivering
    end

    factory :announcement_from_template do
      title nil
      text nil

      association :original_template, factory: :announcement_template

      template_data do
        if original_template
          original_template.spec['fields'].each_with_object({}) do |f, obj|
            field_id = f['id']
            obj[field_id] = "#{field_id} value"
          end
        end
      end

      after :build do |a, evaluator|
        if evaluator.original_template
          evaluator.original_template.save!
          a.original_template = evaluator.original_template
        end
      end
    end
  end
end
