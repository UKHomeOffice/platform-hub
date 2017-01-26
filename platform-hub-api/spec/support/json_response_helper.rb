module JsonResponseHelper
  def json_response
    JSON.parse(response.body)
  end

  def pluck_from_json_response field
    json_response.map { |h| h[field] }
  end
end
