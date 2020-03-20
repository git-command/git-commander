# git-commander

Make your own git commands.

Installation
============

Add this line to your application's Gemfile:

```ruby
gem 'git-commander'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install git-commander

Usage
=====

All commands you register can be run using `git cmd ...`.

Registering a new command is as easy as creating a new `Workflow` file in your git-root's directory (or organize them in a `.git-commands` directory).
Example:

```ruby
# ~/git-root/.git-commands/current.rb

plugin :system

command :current do |cmd|
  cmd.summary "Outputs all commits not on the base branch"
  cmd.argument :base_branch, default: "master"

  cmd.on_run do |options|
    current_branch = system.run "git rev-parse --abbrev-ref HEAD"
    system.run "git log #{options[:base_branch]}..#{current_branch} --format=\"%C(auto)%h %s %C(#999999)%ar\" --color"
  end
end
```

In the above example, we:

1. Use the native `system` plugin.  This gives us access to an instance of [System](/docs/GitCommander/System) inside of our `on_run` block.
2. Creates a new `git cmd current :base_branch` command and runs everything in the `on_run` block when we execute it (passing the `:base_branch` in the `options`)

`cmd` can configure multiple `argument`, `flag`, `switch` options, and a `default: 'some value'` can be set for any.
A long-form `description` can also be set for your commands for use in the command's help text: `git cmd help current`.

You can define multiple commands in a single file if you wish, but it is recommended to keep commands contained to their own file.

Gem usage
=========

Command declaration files can include their own inline gems:

```ruby
gemfile do
  source "https://rubygems.org"
  gem "octokit"
end
```

Plugins
=======

Git-commander is built with the intention of being extended.  To make things
flexible, there is a plugin architecture that allows you to define new top-level
methods that can be available inside of your command's `on_run` blocks.

As a simple example, if you wanted access to a `github` method to perform API calls, you can use the [octokit gem](https://github.com/octokit/octokit.rb) to do this:

```ruby
# .git-commands/plugins/github.rb
gemfile do
  source "https://rubygems.org"
  gem "octokit"
end

Octokit::Client.new
```

Then in a new command, use the new `github` plugin:

```ruby
plugin :github

command :prs do |cmd|
  cmd.summary "Lists all open GitHub PullRequests for the git-commander repo"

  cmd.on_run do |cmd|
    github.pull_requests("codenamev/git-commander", state: "open").each do |pr|
      say "@#{pr.user.login} #{pr.title} – #{pr.html_url}"
    end
  end
end
```

### Anatomy of a plugin

1. [Name of the plugin](#name-of-the-plugin)
2. [Gem dependencies](#gem-dependencies) (via `gemfile` block)
3. [Plugin dependencies](#plugin-dependencies)
4. [Plugin-specific commands](#plugin-specific-commands)
5. [The plugin instance](#the-plugin-instance)

Name of the plugin
------------------

As mentioned in the simple example above, the filename of the plugin defines the keyword that will be available within the `on_run` blocks of your commands. Plugins must be added to your `.git-commands/plugins` directory, and the file extension must be `.rb`. Whatever you name the file becomes the name used internally to reference it.  So if you name your plugin `some-awesome-plugin.rb`, you will have to reference it as `plugin 'some-awesome-plugin'`.

Gem dependencies
----------------

Just like commands, you can include third-party gems using [Bundler's inline helpers](https://github.com/rubygems/bundler/blob/master/lib/bundler/inline.rb).

Plugin dependencies
-------------------

Also the same as with commands, plugins can also define other plugins as dependencies. We include the following plugins natively:

- [git](https://github.com/codenamev/git-commander/blob/master/lib/git_commander/plugins/git.rb)
- [github](https://github.com/codenamev/git-commander/blob/master/lib/git_commander/plugins/github.rb)
- [prompt](https://github.com/codenamev/git-commander/blob/master/lib/git_commander/plugins/prompt.rb)
- [system](https://github.com/codenamev/git-commander/blob/master/lib/git_commander/plugins/system.rb)

Plugin-specific commands
------------------------

Plugins can also define their own commands.  These commands will be namespaced to the name of the plugin.  So the following plugin would allow you to run `git cmd github:setup`.

```ruby
gemfile do
  source "https://rubygems.org"
  gem "octokit"
end

plugin :prompt

command :setup do |cmd|
  cmd.summary "Connects to GitHub, creates an access token, and stores it in the git-cmd section of your git config"

  cmd.on_run do
    gh_user = prompt.ask("Please enter your GitHub username", required: true)
    gh_password = promt.mask("Please enter your GitHub password (this is NOT stored): ", required: true)

    github.login = gh_user
    github.password = gh_password

    # Check for 2-factor requirements
    begin
      client.user
    rescue Octokit::Unauthorized
      github.user(
        gh_user,
        headers: { "X-GitHub-OTP" => prompt.ask("Please enter your two-factor authentication code") }
      )
    end

    say "GitHub account successfully setup!"
  end
end

Octokit::Client.new
```

The plugin instance
-------------------

When plugins are loaded, their content is evaluated in the context of the Plugin::Loader class.  Whatever the file returns (the last line evaluated) is stored as the plugin's instance.  In this way, whenever you reference the plugin from within a command's `on_run`, you are referencing the same instance that was returned from evaluating the plugin's file.

Development
===========

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

Contributing
============

[Bug reports](https://github.com/codenamev/git-commander/issues/new) and [pull requests](https://github.com/codenamev/git-commander/pulls) are welcome on GitHub. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

License
=======

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

Code of Conduct
===============

Everyone interacting in the GitCommander project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/codenamev/git-commander/blob/master/CODE_OF_CONDUCT.md).
