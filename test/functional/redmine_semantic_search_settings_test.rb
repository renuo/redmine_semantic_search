require File.expand_path("../test_helper", __dir__)

class RedmineSemanticSearchSettingsTest < Redmine::ControllerTest
  fixtures :users, :roles

  tests SettingsController

  def setup
    Setting.plugin_redmine_semantic_search = { "enabled" => "1", "base_url" => "https://api.openai.com/v1" }
  end

  def test_non_admin_cannot_access_plugin_settings
    @request.session[:user_id] = 2

    get :plugin, params: { id: "redmine_semantic_search" }
    assert_response :forbidden

    post :plugin, params: {
      id: "redmine_semantic_search",
      settings: {
        enabled: "1",
        base_url: "https://malicious-api.com",
        embedding_model: "custom-model",
        search_limit: "100"
      }
    }
    assert_response :forbidden

    original_settings = Setting.plugin_redmine_semantic_search.dup
    assert_equal original_settings, Setting.plugin_redmine_semantic_search
  end

  def test_basic_auth_warning_shown_when_only_username_set
    @request.session[:user_id] = 1
    ENV["OLLAMA_BASIC_AUTH_USERNAME"] = "user"

    get :plugin, params: { id: "redmine_semantic_search" }

    assert_response :success
    assert_include I18n.t(:warning_redmine_semantic_search_basic_auth_incomplete), response.body
    assert_include "OLLAMA_BASIC_AUTH_USERNAME=#{I18n.t(:label_set)}", response.body
    assert_include "OLLAMA_BASIC_AUTH_PASSWORD=#{I18n.t(:label_not_set)}", response.body
  ensure
    ENV.delete("OLLAMA_BASIC_AUTH_USERNAME")
  end

  def test_basic_auth_warning_shown_when_only_password_set
    @request.session[:user_id] = 1
    ENV["OLLAMA_BASIC_AUTH_PASSWORD"] = "pass"

    get :plugin, params: { id: "redmine_semantic_search" }

    assert_response :success
    assert_include I18n.t(:warning_redmine_semantic_search_basic_auth_incomplete), response.body
  ensure
    ENV.delete("OLLAMA_BASIC_AUTH_PASSWORD")
  end

  def test_basic_auth_warning_not_shown_when_both_set
    @request.session[:user_id] = 1
    ENV["OLLAMA_BASIC_AUTH_USERNAME"] = "user"
    ENV["OLLAMA_BASIC_AUTH_PASSWORD"] = "pass"

    get :plugin, params: { id: "redmine_semantic_search" }

    assert_response :success
    assert_not_include I18n.t(:warning_redmine_semantic_search_basic_auth_incomplete), response.body
    assert_include "OLLAMA_BASIC_AUTH_USERNAME=#{I18n.t(:label_set)}", response.body
    assert_include "OLLAMA_BASIC_AUTH_PASSWORD=#{I18n.t(:label_set)}", response.body
  ensure
    ENV.delete("OLLAMA_BASIC_AUTH_USERNAME")
    ENV.delete("OLLAMA_BASIC_AUTH_PASSWORD")
  end

  def test_basic_auth_warning_not_shown_when_neither_set
    @request.session[:user_id] = 1
    ENV.delete("OLLAMA_BASIC_AUTH_USERNAME")
    ENV.delete("OLLAMA_BASIC_AUTH_PASSWORD")

    get :plugin, params: { id: "redmine_semantic_search" }

    assert_response :success
    assert_not_include I18n.t(:warning_redmine_semantic_search_basic_auth_incomplete), response.body
    assert_include "OLLAMA_BASIC_AUTH_USERNAME=#{I18n.t(:label_not_set)}", response.body
    assert_include "OLLAMA_BASIC_AUTH_PASSWORD=#{I18n.t(:label_not_set)}", response.body
  end
end
