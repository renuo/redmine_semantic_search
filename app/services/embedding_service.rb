require "ruby/openai"
require "base64"

class EmbeddingService
  class EmbeddingError < StandardError; end

  MAX_DIMENSION = 2000
  DEFAULT_BASE_URL = "https://api.openai.com/v1".freeze

  def initialize
    @client = OpenAI::Client.new(access_token: api_key, uri_base: base_url, extra_headers: extra_headers)
  end

  def generate_embedding(text)
    Rails.logger.info("Generating embedding for text: #{text}")
    response = @client.embeddings(
      parameters: {
        model: embedding_model,
        input: text
      }
    )

    if response["error"]
      Rails.logger.error("OpenAI API error: #{response['error']}")
      raise EmbeddingError, "Failed to generate embedding: #{response['error']['message']}"
    end

    pad_embedding(response.dig("data", 0, "embedding"))
  rescue Faraday::Error => e
    Rails.logger.error("OpenAI API connection error: #{e.message}")
    raise EmbeddingError, "Connection error while generating embedding: #{e.message}"
  end

  def pad_embedding(vector)
    return vector if vector.nil? || vector.length >= MAX_DIMENSION

    vector + Array.new(MAX_DIMENSION - vector.length, 0.0)
  end

  def model_dimensions
    # we have different vector sizes for different models
    case embedding_model
    when "nomic-embed-text" # ollama
      768
    when "text-embedding-ada-002" # openai
      1536
    else
      2000
    end
  end

  def prepare_issue_content(issue)
    [
      "Issue ##{issue.id} - #{issue.subject}",
      "Description: #{issue.description}",
      issue.journals.map { |j| "Comment: #{j.notes}" if j.notes.present? }.compact.join("\n"),
      issue.time_entries.map { |te| "Time entry note: #{te.comments}" if te.comments.present? }.compact.join("\n")
    ].join("\n").strip
  end

  private

  def api_key
    key = ENV.fetch("OPENAI_API_KEY", nil)
    return key if key.present?
    # Self-hosted, OpenAI-compatible endpoints (e.g. Ollama) need no key.
    return nil if using_custom_base_url?

    raise EmbeddingError, I18n.t("error_redmine_semantic_search_openai_api_key_required")
  end

  def base_url
    @base_url ||= Setting.plugin_redmine_semantic_search["base_url"] || DEFAULT_BASE_URL
  end

  def using_custom_base_url?
    base_url.to_s.strip.chomp("/") != DEFAULT_BASE_URL
  end

  def extra_headers
    header = basic_auth_header
    return {} if header.nil?

    { "Authorization" => header }
  end

  def basic_auth_header
    return nil unless using_custom_base_url?

    username = ENV.fetch("OLLAMA_BASIC_AUTH_USERNAME", nil)
    password = ENV.fetch("OLLAMA_BASIC_AUTH_PASSWORD", nil)
    return nil if username.blank? && password.blank?

    if username.blank? || password.blank?
      Rails.logger.warn("Ignoring basic auth: set both OLLAMA_BASIC_AUTH_USERNAME and OLLAMA_BASIC_AUTH_PASSWORD")
      return nil
    end

    "Basic #{Base64.strict_encode64("#{username}:#{password}")}"
  end

  def embedding_model
    Setting.plugin_redmine_semantic_search["embedding_model"] || "text-embedding-ada-002"
  end
end
