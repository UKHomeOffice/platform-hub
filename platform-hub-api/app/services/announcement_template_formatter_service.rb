module AnnouncementTemplateFormatterService

  def self.format templates, data
    results = {
      title: templates['title'].clone,
      on_hub: templates['on_hub'].clone,
      email_html: templates['email_html'].clone,
      email_text: templates['email_text'].clone,
      slack: templates['slack'].clone
    }
    results.each do |_, template|
      data.each do |field_name, field_value|
        string_value = case field_value
          when Array
            field_value.join(', ')
          else
            field_value.to_s
          end
        interpolate! template, field_name, string_value
      end
    end

    # Special case for on hub + email HTML
    results[:on_hub] = Rinku.auto_link(results[:on_hub])
    results[:email_html] = Rinku.auto_link(results[:email_html])

    Results.new results
  end

  private_class_method def self.interpolate! string, field_name, field_value
    string.gsub! "{{#{field_name}}}", field_value
  end

  class Results < Hashie::Dash
    property :title, required: true
    property :on_hub, required: true
    property :email_html, required: true
    property :email_text, required: true
    property :slack, required: true
  end

end
