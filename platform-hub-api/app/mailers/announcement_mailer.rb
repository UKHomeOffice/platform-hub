class AnnouncementMailer < ApplicationMailer

  include ActionView::Helpers::TextHelper

  def announcement_email announcement, recipients
    @announcement_text = announcement.text
    @announcement_html = simple_format(Rinku.auto_link(announcement.text))

    subject = "[#{announcement.level}] #{announcement.title}"

    mail(
      to: Rails.application.config.email_from_address,
      bcc: recipients,
      subject: subject
    )
  end

end
