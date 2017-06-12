class AnnouncementMailer < ApplicationMailer

  include ActionView::Helpers::TextHelper

  def announcement_email announcement, recipients
    @announcement_text = announcement.text
    @announcement_html = simple_format(announcement.text, {}, wrapper_tag: 'div')

    subject = "[#{announcement.level}] #{announcement.title}"

    mail to: recipients, subject: subject
  end

end
