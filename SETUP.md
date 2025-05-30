# Setup Guide

This Guide will give you a step-by-step Tutorial on how to set this Plugin up.

## Pre-requisites

Before we get started, make sure you have the following done already.

✅ A valid Redmine 5.1 or 6.0 instance (see [Setting Up Redmine](#setting-up-redmine))
<br />
✅ Optional: Your OpenAI API Key. Get it [here](https://platform.openai.com/api-keys).

# Plugin Setup

First, clone the plugin repository into the `plugins` directory of your Redmine instance.
It's assumed you are in your Redmine root directory when you run the following command:

```bash
git clone https://github.com/renuo/redmine_semantic_search plugins/redmine_semantic_search
```

Next, install the required system-wide dependencies (this will install both `postgresql` and `pgvector` if you don't have them):

```bash
brew install postgresql@16 pgvector
```

Then, make sure you are still in the root directory of redmine, and install the dependencies of the newly added plugin:

```bash
bundle install
```

After the plugin's dependencies are installed, navigate back to your Redmine root directory. From the Redmine root, run the plugin's database migrations:

```bash
cd ../..
RAILS_ENV=production bundle exec rake redmine:plugins:migrate NAME=redmine_semantic_search
```

Finally, restart your Redmine application server for the plugin to be loaded and active.
If you are running the standard Rails development server, you can typically stop it (usually with `Ctrl+C` in the terminal where it's running) and then restart it. For example:

```bash
# Stop your current server (e.g., Ctrl+C)
# Then restart it, for example:
RAILS_ENV=production bundle exec rails server
```

> [!IMPORTANT]
> The semantic search plugin is disabled by default, so make sure to enable it in the [plugin settings](http://localhost:3000/settings/plugin/redmine_semantic_search).

Now you can assign roles and permissions to determine who can use the semantic search feature.

You can do this in by going to the role you want to change the permissions for, then selecting the checkbox "Use semantic search" under the section "Redmine semantic search":

![Checkbox Showcase](repo/checkbox-showcase.gif)

## Choosing an Embedding Provider

This plugin supports different providers for generating embeddings. Choose one of the following options:

### Option 1: Using Ollama (Recommended for Local Testing)

Ollama allows you to run large language models locally. This is a great option for testing without incurring API costs.

1.  **Install and Configure Ollama:**
    Execute the following commands in your terminal:
    ```bash
    brew install ollama
    brew services start ollama
    ollama pull nomic-embed-text:latest # This model will run on port 11434 by default
    ```

2.  **Configure Plugin Settings:**
    Navigate to the plugin settings in Redmine (at `http://localhost:3000/settings/plugin/redmine_semantic_search`) and enter the following details:
    *   **Base URL:** `http://localhost:11434/v1`
    *   **Embedding Model:** `nomic-embed-text:latest`

3.  **Set API Key for Ollama:**
    For the connection to work correctly with Ollama, the `OPENAI_API_KEY` must be set to `ollama`.
    It's recommended to create a `.env` file in your Redmine root directory and add the following line:
    ```env
    OPENAI_API_KEY=ollama
    ```
    Then, ensure your Redmine server loads this `.env` file (e.g., by using a gem like `dotenv-rails`).
    Alternatively, you can set this in your shell profile (e.g., `.zshrc`, `.bashrc`) or when starting your Redmine server:
    ```bash
    OPENAI_API_KEY=ollama RAILS_ENV=production bundle exec rails server
    ```

### Option 2: Using OpenAI

If you prefer to use OpenAI's models for embeddings:

1.  **Ensure API Key is Set:**
    Make sure you have your OpenAI API Key.
    It's recommended to create a `.env` file in your Redmine root directory and add the following line, replacing `"YOUR_OPENAI_API_KEY"` with your actual key:
    ```env
    OPENAI_API_KEY="YOUR_OPENAI_API_KEY"
    ```
    Then, ensure your Redmine server loads this `.env` file (e.g., by using a gem like `dotenv-rails`).
    Alternatively, you can set it as an environment variable:
    ```bash
    export OPENAI_API_KEY="YOUR_OPENAI_API_KEY"
    ```
    It's recommended to add this to your shell profile (e.g., `.zshrc`, `.bashrc`) for persistence if not using a `.env` file.

2.  **Configure Plugin Settings:**
    Navigate to the plugin settings in Redmine (at `http://localhost:3000/settings/plugin/redmine_semantic_search`) and enter the following details:
    *   Leave the **Base URL** empty to use the default OpenAI API URL.
    *   Enter your desired **Embedding Model** (e.g., `text-embedding-ada-002`).

## Usage

At this point, you are ready to test the actual functionality of the plugin.

First, make sure you have at least 4 issues, so search results actually make sense.

Once you've configured your chosen embedding provider:

1.  Navigate to the Projects Page (e.g., `http://localhost:3000/projects`).
2.  Click on the "Sync Embeddings" button located at the end of the toolbar:

    ![Sync Embeddings Showcase](repo/sync-showcase.gif)

3.  Wait a couple of seconds for the embeddings to be generated and stored.
4.  Navigate to the "Semantic Search" tab in the navbar.
5.  Test the plugin by entering a keyword from the previously created issues. The relevant issues should appear in the search results with an according similarity score.

![Search Results](repo/results.png)

## Quick Data Setup for Development/Testing

To quickly populate your Redmine instance with sample projects and issues for testing the Semantic Search plugin, you can use the provided setup script. This script will create two projects, each with ten relevant issues.

1.  **Ensure your plugin is in the correct directory:** The `redmine_semantic_search` plugin directory must be located within your Redmine installation's `plugins` folder (e.g., `your_redmine_root/plugins/redmine_semantic_search/`).

2.  **Navigate to the plugin directory:**
    ```bash
    cd path/to/your/redmine/plugins/redmine_semantic_search
    ```

3.  **Make the script executable (if you haven't already):**
    ```bash
    chmod +x bin/setup
    ```

4.  **Run the setup script:**
    You must specify the `RAILS_ENV` (it defaults to `development`). Next, run this command:
    ```bash
    RAILS_ENV=production ./bin/setup
    ```

    The script will output its progress, indicating the creation of projects and issues. The output will be colorized for better readability.

This will give you a good set of data to test the "Sync Embeddings" and semantic search functionalities described in the [Usage](#usage) section above.

# Setting up Redmine

If you haven't set up Redmine, refer to this guide.

1. Make sure you have `ruby-3.2.8` installed.

There are multiple ways to install this ruby verison, but the one I recommend is the following

- Install `rbenv`, a ruby installation manager: `brew install rbenv`
- Install `ruby` version 3.2.8 using: `rbenv install 3.2.8`

2. After `ruby` is ready, clone redmine into a directory of your choice, preferrably `~`.

```bash
git clone https://github.com/redmine/redmine.git # This is a GitHub mirror of Redmine, not the official one
cd redmine
```

3. Once you have redmine locally, configure `database.yml`:

```bash
cp config/database.yml.example config/database.yml
vim config/database.yml # or any other editor of choice
```

Then paste in the following contents:

```yaml
production:
  adapter: postgresql
  database: redmine
  encoding: unicode

development:
  adapter: postgresql
  database: redmine_development
  encoding: unicode

test:
  adapter: postgresql
  database: redmine_test
  encoding: unicode
```

> [!TIP]
> If you face any issues with the Postgres Database Setup, try pasting [this](repo/backup_database.yml) into `config/database.yml` instead.

4. Now set the local ruby version to 3.2.8.

```bash
rbenv local 3.2.8
```

5. After that, install the dependencies with `bundle`.

```bash
bundle install
```

6. In order to setup our database, we now need to create the database, then run the migrations.

> [!WARNING]
> If you already have a database called `redmine`, make sure to delete it first using `dropdb -U postgres redmine`.

```bash
export RAILS_ENV=production
bundle exec rake generate_secret_token
bundle exec rake db:create
bundle exec rake db:migrate
bundle exec rake redmine:load_default_data
```

7. Then, run the development server.

```bash
RAILS_ENV=production bundle exec rails server
```

8. Visit `http://localhost:3000` in your browser, and enter `admin` as the login and `admin` as the password.

9. Next you will be prompted to change your password, choose one and write it down for later.

10. As of now, it is recommended to create a project and add a couple of issues to it, so testing the Semantic Search actually becomes feasible.

> [!TIP]
> If you don't want to go through the hassle of manually creating projects & issues, you can use the `bin/setup` script as described in the [Quick Data Setup for Development/Testing](#quick-data-setup-for-developmenttesting) section.
