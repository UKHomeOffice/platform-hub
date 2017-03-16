module SupportRequestFormatterService

  def self.format template, data, user
    identity = user.identity 'github'

    submitter_text = if identity
      "@#{identity.external_username}"
    else
      "#{user.name} (#{user.email})"
    end

    body_text_lines = []
    body_text_lines << "Requested by: #{submitter_text}"
    body_text_lines << ""
    if template['git_hub_issue_spec']['body_text_preamble']
      body_text_lines << template['git_hub_issue_spec']['body_text_preamble']
      body_text_lines << ""
    end
    body_text_lines << "| Field | Value provided |"
    body_text_lines << "|  ---: | -------------- |"
    template['form_spec']['fields'].each do |spec|
      body_text_lines << "| #{spec['label']} | #{data[spec['id']] || '--'} |"
    end

    title_text = template['git_hub_issue_spec']['title_text'] + " [#{submitter_text}]"

    Result.new title: title_text, body: body_text_lines.join("\n");
  end


  class Result < Hashie::Dash
    property :title, required: true
    property :body, required: true
  end

end
