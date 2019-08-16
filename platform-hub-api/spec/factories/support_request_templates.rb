FactoryBot.define do
  factory :support_request_template do
    id { SecureRandom.uuid }

    sequence :shortname do |n|
      "Support Request Type #{n}"
    end

    git_hub_repo { 'https://github.com/ACMECorp/support-requests' }

    sequence :title do |n|
      "Support request for getting #{n} sorted out"
    end

    description { 'This is a support request for getting something sorted out' }

    transient do
      fields_count { 1 }
    end

    after :build do |srt, evaluator|
      fields = evaluator.fields_count.times.map do |ix|
        {
          id: "usernameRequested#{ix}",
          label: "Username Requested #{ix}",
          field_type: 'text',
          required: true,
          placeholder: 'Type the username you would like to be created for you',
          help_text: 'Try to keep this as short as possible. Only use \'_\' and \'-\'  for special characters'
        }
      end

      srt.form_spec = {
        help_text: 'Use this form to submit details about your request',
        fields: fields
      }
    end

    git_hub_issue_spec do
      {
        title_text: 'This is a support request',
        body_text_preamble: 'User requested some usernames:'
      }
    end

  end
end
