module AnnouncementTemplateFormatterService

  def self.format templates, data
    templates = HashWithIndifferentAccess.new(templates)

    results = AnnouncementTemplate::TEMPLATE_DEFINITION_TYPES.map do |t|
      [ t, templates[t].clone ]
    end.to_h

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
    AnnouncementTemplate::TEMPLATE_DEFINITION_TYPES.each do |t|
      property t, required: true
    end
  end

end
