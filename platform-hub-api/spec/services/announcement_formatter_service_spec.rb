require 'rails_helper'

describe AnnouncementFormatterService, type: :service do

  describe '.format' do

    let :title_template do
      'Hello {{user_name}}'
    end

    let :on_hub_template do
      <<~TEXT
        Today we release {{service_names}} on to the world

        This your chance to be a pioneer, {{user_name}}!
      TEXT
    end

    let :email_html_template do
      <<~HTML
        <div>
          Today we release {{service_names}} on to the world
        </div>
        <br />
        <div>This your chance to be a pioneer, {{user_name}}!</div>
      HTML
    end

    let :email_text_template do
      <<~TEXT
        Today we release {{service_names}} on to the world

        This your chance to be a pioneer, {{user_name}}!
      TEXT
    end

    let :slack_template do
      'NOTHING'
    end

    let :templates do
      {
        'title' => title_template,
        'on_hub' => on_hub_template,
        'email_html' => email_html_template,
        'email_text' => email_text_template,
        'slack' => slack_template
      }
    end

    let :data do
      {
        user_name: 'foo',
        service_names: [ 'bar', 'soap' ]
      }
    end

    let :title_result do
      'Hello foo'
    end

    let :on_hub_result do
      <<~TEXT
        Today we release bar, soap on to the world

        This your chance to be a pioneer, foo!
      TEXT
    end

    let :email_html_result do
      <<~HTML
        <div>
          Today we release bar, soap on to the world
        </div>
        <br />
        <div>This your chance to be a pioneer, foo!</div>
      HTML
    end

    let :email_text_result do
      <<~TEXT
        Today we release bar, soap on to the world

        This your chance to be a pioneer, foo!
      TEXT
    end

    let :slack_result do
      'NOTHING'
    end

    let :results do
      AnnouncementFormatterService::Results.new(
        title: title_result,
        on_hub: on_hub_result,
        email_html: email_html_result,
        email_text: email_text_result,
        slack: slack_result
      )
    end

    it 'should apply the fields data to the templates and produce the expected output results' do
      expect(AnnouncementFormatterService.format(templates, data)).to eq results
    end
  end

end
