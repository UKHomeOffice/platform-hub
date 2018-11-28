require "rails_helper"

RSpec.describe AnnouncementMailer, type: :mailer do

  describe '.announcement_email' do
    let(:from) { Rails.application.config.email_from_address }

    let :recipients do
      [
        'foo@example.org',
        'bar@example.org'
      ]
    end

    context 'for an announcement with content' do
      let :text do
        <<~TEXT
          Hello,

          This is an email announcement of epic foo proportions…

          - foo
          - bar
          - baz

          Don't miss out: https://foo.com

          Faithfully yours,
          The Foo Team
        TEXT
      end

      let(:announcement) { create :announcement, text: text }

      let :expected_subject do
        "[#{announcement.level}] #{announcement.title}"
      end

      let :expected_text do
        text.strip.gsub("\n", "\r\n")
      end

      let :expected_html do
        html = <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
            </head>

            <body>
              <p>Hello,</p>

          <p>This is an email announcement of epic foo proportions…</p>

          <p>- foo
          <br />- bar
          <br />- baz</p>

          <p>Don't miss out: <a href="https://foo.com">https://foo.com</a></p>

          <p>Faithfully yours,
          <br />The Foo Team
          </p>
          <br><br>

            </body>
          </html>
        HTML
        html.strip.gsub("\n", "\r\n")
      end

      before do
        @email = AnnouncementMailer.announcement_email announcement, recipients
      end

      it 'queues the email' do
        assert_emails 1 do
          @email.deliver_now
        end
      end

      it 'renders the email (both in text and html)' do
        expect(@email[:from].value).to eq from
        expect(@email[:to].value).to eq from
        expect(@email.bcc).to eq recipients
        expect(@email.subject).to eq expected_subject
        expect(@email.text_part.body.to_s.strip).to eq expected_text
        expect(@email.html_part.body.to_s).to match expected_html
      end
    end

    context 'for a template based announcement' do
      # We assume here that the announcement template factory creates a spec
      # with a valid field as well as valid template definitions, and that the
      # announcement factory creates the needed template_data for this field.
      let(:template) { create :announcement_template, fields_count: 1  }
      let(:announcement) { create :announcement_from_template, original_template: template }
      let(:field_id) { template.spec['fields'].first['id'] }
      let(:field_value) { announcement.template_data[field_id] }
      let(:template_definitions) { template.spec['templates'] }

      let :expected_subject do
        title = template_definitions['title'].gsub("{{#{field_id}}}", field_value)
        "[#{announcement.level}] #{title}"
      end

      let :expected_text do
        template_definitions['email_text'].gsub("{{#{field_id}}}", field_value).strip
      end

      let :expected_html do
        content = template_definitions['email_html'].gsub("{{#{field_id}}}", field_value)

        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
            </head>

            <body>
              #{content}
          <br><br>

            </body>
          </html>
        HTML
      end

      before do
        @email = AnnouncementMailer.announcement_email announcement, recipients
      end

      it 'renders the email (both in text and html)' do
        expect(@email[:from].value).to eq from
        expect(@email[:to].value).to eq from
        expect(@email.bcc).to eq recipients
        expect(@email.subject).to eq expected_subject
        expect(@email.text_part.body.to_s.strip).to eq expected_text
        expect(@email.html_part.body.to_s).to match expected_html
      end
    end
  end

end
