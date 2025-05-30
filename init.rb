require "logger"

require "dotenv/load"
require "ruby/openai"

require "pathname"
plugin_root = Pathname.new(__FILE__).dirname
lib_dir = plugin_root.join("lib")
$LOAD_PATH.unshift(lib_dir.to_s) unless $LOAD_PATH.include?(lib_dir.to_s)

require_dependency "redmine_semantic_search/issue_hooks"
require_dependency "redmine_semantic_search/hooks/view_hooks"

Redmine::Plugin.register :redmine_semantic_search do
  name "Semantic Search"
  author "Sami Hindi @ Renuo"
  description "This redmine plugin allows you to search issues using natural language, by storing the issue content in a vector database."
  version "0.0.1"
  url "https://github.com/renuo/redmine_semantic_search"
  author_url "https://github.com/renuo"

  settings default: {
    "enabled" => "0",
    "base_url" => "https://api.openai.com/v1",
    "embedding_model" => "text-embedding-ada-002",
    "search_limit" => 25,
  }, partial: "settings/redmine_semantic_search_settings"

  menu :top_menu, :redmine_semantic_search,
       { controller: "redmine_semantic_search", action: "index" },
       caption: :label_redmine_semantic_search,
       if: Proc.new {
         user = User.current
         Setting.plugin_redmine_semantic_search['enabled'] == '1' &&
           user.logged? &&
           user.allowed_to?(:use_semantic_search, nil, global: true)
       }

  menu :application_menu, :redmine_semantic_search_sync_embeddings,
       { controller: "redmine_semantic_search", action: "sync_embeddings" },
       caption: :button_redmine_semantic_search_sync_embeddings,
       html: { method: :post },
       if: Proc.new {
         user = User.current
         user.admin?
       }

  project_module :redmine_semantic_search do
    permission :use_semantic_search, { redmine_semantic_search: [:index] }
  end
end

RedmineSemanticSearch::IssueHooks.instance
