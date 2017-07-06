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
      "#{text}\n\n"  # Because we have extra newlines in the template
    end

    let :expected_html do
      <<~HTML
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
      expect(@email.text_part.body.to_s).to eq expected_text
      puts
    end
  end

end
