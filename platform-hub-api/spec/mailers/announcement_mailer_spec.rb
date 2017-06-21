require "rails_helper"

RSpec.describe AnnouncementMailer, type: :mailer do

  describe '.announcement_email' do
    context 'a very simple one line announcement' do
      let(:from) { [ Rails.application.config.email_from_address ] }

      let :recipients do
        [
          'foo@example.org',
          'bar@example.org'
        ]
      end

      let(:text) { 'foo bar'}
      let(:announcement) { create :announcement, text: text }

      let :expected_subject do
        "[#{announcement.level}] #{announcement.title}"
      end
      let :expected_text do
        "#{text}\n\n"  # Because we have extra newlines in the template
      end
      let :expected_html do
        "<div>#{text}</div>\n<br><br>"
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
        expect(@email.from).to eq from
        expect(@email.to).to eq from
        expect(@email.bcc).to eq recipients
        expect(@email.subject).to eq expected_subject
        expect(@email.text_part.body.to_s).to eq expected_text
        expect(@email.html_part.body.to_s).to match expected_html
      end
    end
  end

end
