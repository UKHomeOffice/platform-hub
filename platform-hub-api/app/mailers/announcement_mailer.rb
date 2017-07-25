class AnnouncementMailer < ApplicationMailer

  include ActionView::Helpers::TextHelper

  def announcement_email announcement, recipients
    if announcement.template_data.present?
      output = AnnouncementTemplateFormatterService.format announcement.template_definitions, announcement.template_data
      @announcement_title = output.title
      @announcement_text = output.email_text
      @announcement_html = output.email_html.html_safe
    else
      @announcement_title = announcement.title
      @announcement_text = announcement.text
      @announcement_html = simple_format(Rinku.auto_link(announcement.text))
    end

    subject = "[#{announcement.level}] #{@announcement_title}"

    mail(
      to: Rails.application.config.email_from_address,
      bcc: recipients,
      subject: subject
    )
  end

end
