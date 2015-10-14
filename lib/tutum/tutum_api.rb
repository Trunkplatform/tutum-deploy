require 'rest-client'

class TutumApi
  def http_get(path, params={})
    query =  "?" + params.map { |k,v| "#{k}=#{v}"}.join("&")
    full_path = path
    full_path += query unless params.empty?
    response = RestClient.get(url(full_path), headers)
    JSON.parse(response, :symbolize_names => true)
  end

  def http_post(path, content={})
    response = RestClient.post(url(path), content.to_json, headers)
    JSON.parse(response, :symbolize_names => true)
  end

  def http_patch(path, content={})
    response = RestClient.patch(url(path), content.to_json, headers)
    JSON.parse(response, :symbolize_names => true)
  end

  def http_delete(path)
    response = RestClient.delete(url(path), headers)
    JSON.parse(response, :symbolize_names => true)
  end
end
