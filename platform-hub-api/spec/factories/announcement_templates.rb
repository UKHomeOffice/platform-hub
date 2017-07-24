FactoryGirl.define do
  factory :announcement_template do
    id { SecureRandom.uuid }

    sequence :shortname do |n|
      "Announcement Type #{n}"
    end

    description 'This is a template for an announcement'

    transient do
      fields_count 1
      templates do
        {
          'title': 'Title {{field1}}',
          'on_hub': 'On hub {{field1}}',
          'email_html': 'Email HTML <p>{{field1}}</p>',
          'email_text': 'Email text {{field1}}',
          'slack': 'Slack {{field1}}'
        }
      end
    end

    after :build do |at, evaluator|
      fields = evaluator.fields_count.times.map do |ix|
        {
          id: "field#{ix}",
          label: "Field #{ix}",
          field_type: 'text',
          required: true,
          placeholder: 'Type some fancy text',
          help_text: 'Try to keep this as short as possible'
        }
      end

      at.spec = {
        fields: fields,
        templates: evaluator.templates
      }
    end
  end
end
