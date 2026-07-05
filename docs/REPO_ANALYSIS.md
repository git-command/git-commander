# git-commander — Repository Analysis

*An in-depth review of how this codebase works, the value it provides, how it is designed,
and where it has flaws or room to improve.*

- [What this project is](#what-this-project-is)
- [The value it provides](#the-value-it-provides)
- [How it works](#how-it-works)
- [Design assessment](#design-assessment)
- [Current health](#current-health)
- [Confirmed bugs](#confirmed-bugs)
- [Design flaws and rough edges](#design-flaws-and-rough-edges)
- [Security considerations](#security-considerations)
- [Recommended improvements](#recommended-improvements)

---

## What this project is

**git-commander** is a Ruby gem (v0.1.0, unreleased) that lets developers define their own
git subcommands in a small Ruby DSL and run them as `git cmd <name>`. Command definitions
live in the repository they belong to — a `Workflow` file at the git root, or files under
`.git-commands/` — so custom workflows travel with the project and are shared with the whole
team through version control.

A minimal command:

```ruby
# .git-commands/current.rb
plugin :system

command :current do |cmd|
  cmd.summary "Outputs all commits not on the base branch"
  cmd.argument :base_branch, default: "master"

  cmd.on_run do |options|
    current_branch = system.run "git rev-parse --abbrev-ref HEAD"
    system.run "git log #{options[:base_branch]}..#{current_branch}"
  end
end
```

Running `git cmd current main` executes the `on_run` block with `options[:base_branch] == "main"`.

## The value it provides

The niche it targets sits between two existing options:

- **Git aliases** are limited to one-liners, have no argument parsing, no help text, and no
  way to pull in libraries.
- **Standalone scripts** (Thor CLIs, `bin/` scripts) get you all of that, but each one
  reinvents option parsing, help output, and dependency setup, and they don't compose.

git-commander's pitch is a *framework* for repo-local git tooling:

1. **Declarative option handling** — `argument`, `flag`, and `switch` declarations with
   defaults and descriptions, wired automatically into Ruby's `OptionParser` and into
   generated help text.
2. **A plugin system** — plugins expose named objects (`git`, `github`, `prompt`, `system`)
   inside command blocks, so command authors write against high-level APIs instead of
   shelling out. Plugins can declare their own namespaced commands (`git cmd github:setup`)
   and depend on other plugins.
3. **Inline gem dependencies** — command and plugin files can declare gems via Bundler's
   inline `gemfile` block, so a workflow file is self-describing about what it needs.
4. **Team distribution for free** — because definitions live in the repo, `git clone` is
   the installation step for everyone else.
5. **Testing support** — `GitCommander::RSpec::PluginHelpers` ships with the gem so plugin
   authors can stub inline gemfiles and assert on declared gems.

## How it works

### Runtime flow

```
git cmd current main
        │
        ▼
exe/git-cmd ──── discovers & loads:  ./Workflow, .git-commands/*.rb   (commands)
        │                            .git-commands/plugins/*.rb       (plugins)
        ▼
CLI#run ── Registry#find(:current) ── OptionParser parses flags/switches,
        │                             positional args assigned in order
        ▼
Command#run ── Runner.new(self).run(options_hash)
        │
        ▼
Runner#instance_exec(**options, &command.block)
        │
        └─ method_missing(:system) → Registry#find_plugin(:system).executor
                                     (SimpleDelegator around the plugin instance)
```

### Component map

| Component | File | Responsibility |
|---|---|---|
| `exe/git-cmd` | `exe/git-cmd` | Entry point; globs command/plugin files from the working directory and loads them into a registry, then hands `ARGV` to the CLI |
| `CLI` | `lib/git_commander/cli.rb` | Maps `ARGV` to a registered command; builds an `OptionParser` from the command's declared flags/switches; prints global help on unknown commands |
| `Registry` | `lib/git_commander/registry.rb` | Hash-backed store of commands and plugins; `load(LoaderClass, *args)` runs a loader and registers its results on success |
| `Command` | `lib/git_commander/command.rb` | Holds a command's name, options (`arguments`/`flags`/`switches`), help text, and the `on_run` block |
| `Command::Option` | `lib/git_commander/command/option.rb` | Value object normalizing arguments, flags, and switches (name, default, description, value) |
| `Command::Runner` | `lib/git_commander/command/runner.rb` | Execution context for `on_run` blocks; `method_missing` resolves bare words to plugin executors |
| `Command::Configurator` | `lib/git_commander/command/configurator.rb` | Builds a `Command` from a DSL block via `instance_exec`, wrapping failures in `ConfigurationError` |
| `CommandLoaderOptions` | `lib/git_commander/command_loader_options.rb` | The DSL mixin: `summary`, `description`, `argument`, `flag`, `switch`, `on_run` |
| `Loader` / `LoaderResult` | `lib/git_commander/loader.rb`, `loader_result.rb` | Abstract loader interface; result object accumulating `commands`, `plugins`, `errors` |
| `Loaders::Raw` | `lib/git_commander/command/loaders/raw.rb` | `instance_eval`s a Ruby string; exposes `command` and `plugin` as top-level DSL keywords |
| `Loaders::FileLoader` | `lib/git_commander/command/loaders/file_loader.rb` | Reads a file and delegates to `Raw` |
| `Plugin` / `Plugin::Executor` | `lib/git_commander/plugin.rb`, `plugin/executor.rb` | Wraps a plugin's source instance in a `SimpleDelegator` for use inside command blocks |
| `Plugin::Loader` | `lib/git_commander/plugin/loader.rb` | Resolves a plugin by symbol (bundled plugins in `lib/git_commander/plugins/`) or file path; `instance_eval`s it; the file's **last expression** becomes the plugin instance |
| `System` | `lib/git_commander/system.rb` | `Open3.capture3` wrapper for shell commands with logging and error raising |
| `Logger` | `lib/git_commander/logger.rb` | File logger, defaulting to `/tmp/git-commander.log`, path configurable via `git config commander.log-file-path` |

### The loading pipeline

Loading is the most interesting part of the design. Everything is evaluated Ruby:

1. `FileLoader` reads a file and passes the source string to `Raw`.
2. `Raw#load` calls `instance_eval` on the string. Inside that context:
   - `command(:name) { |cmd| ... }` → `Configurator` creates a `Command` and `instance_exec`s
     the block against it, so `cmd.summary`, `cmd.argument`, `cmd.on_run` etc. (from
     `CommandLoaderOptions`) configure it.
   - `plugin(:name)` → `Plugin::Loader` recursively loads the named plugin.
3. `Plugin::Loader#load` reads the plugin file (bundled dir for symbols, literal path for
   strings) and `instance_eval`s it. The plugin file may itself call `gemfile` (Bundler
   inline), `plugin` (dependencies), and `command` (namespaced as `plugin-name:command`).
   Whatever the file's last expression returns is wrapped in `Plugin::Executor`
   (a `SimpleDelegator`) and becomes the object command blocks talk to.
4. All results funnel into a `LoaderResult`; `Registry#load` registers the commands and
   plugins only if the result has no errors. Exceptions — including `SyntaxError`, hence the
   deliberate `rescue Exception` in `Raw` — are captured as result errors rather than crashing.

### The plugin bridge

At run time, `Runner` `undef`s Ruby's built-in `system` so that bare-word references inside
`on_run` blocks fall through to `method_missing`, which looks the name up in the registry's
plugins and returns its executor. That is how `system.run "git status"` and
`github.pull_requests(...)` work without any explicit receiver — a clean trick that keeps
the command-author API minimal.

The four bundled plugins illustrate the range: `system` returns the `GitCommander::System`
class itself; `prompt` returns a `TTY::Prompt` instance; `git` returns a Rugged repository
wrapped so that "global" config writes go to `~/.gitconfig.commander`; `github` returns an
`Octokit::Client` and declares a `github:setup` command.

## Design assessment

**What's good:**

- **Clear separation of concerns.** CLI parsing, the registry, command configuration,
  execution context, and loading are all separate small classes with narrow interfaces.
  The `Loader`/`LoaderResult` pattern gives uniform error accumulation across loaders.
- **The DSL is genuinely ergonomic.** A useful command is ~10 lines; option parsing and
  help text come free. The `instance_exec`-with-`cmd`-yield pattern in `Configurator`
  supports both `cmd.summary` and bare `summary` styles.
- **Error containment is deliberate.** A broken workflow file logs a warning instead of
  breaking every other command — the right call for a tool that evaluates user-authored code.
- **Failure-tolerant loading is tested.** The spec suite (77 examples) covers loaders,
  registry, CLI parsing, and end-to-end feature specs that shell out to the real executable.
- **Shipping test helpers for plugin authors** shows unusual care for the extension
  ecosystem the project wants to grow.

**Structural weaknesses (details in the flaw sections below):**

- Everything rides on `instance_eval`/`method_missing` metaprogramming, which is flexible
  but makes failures indirect and enables several of the confirmed bugs.
- There is duplicated logic that has already drifted: help-text formatting exists in both
  `CLI` and `Command`; the `command`/`plugin` DSL methods are duplicated between `Raw` and
  `Plugin::Loader`; `handle_error` is copy-pasted across three loaders.
- Commands are mutable singletons in the registry — parsed option *values* are written back
  onto the registered `Command` object, so state leaks between runs in any long-lived process.
- Some names mislead: `System.run`'s `:blocking` option actually means "raise on failure",
  and `:silent` controls echoing output to STDOUT, bypassing the command's configured
  output IO entirely.

## Current health

Assessed 2026-07 on this checkout (`main` @ `50c0f9f`):

- **Version 0.1.0, apparently never released** to RubyGems; the homepage still points to
  `codenamev/git-commander` while the repo lives under `git-command/`.
- **Test suite: 77 examples, 2 failures** on Ruby 3.3.6. Both failures are
  `Encoding::CompatibilityError`s in feature specs comparing the en-dash (`–`) in help
  output against US-ASCII strings — environment/encoding artifacts, not logic failures.
  On the CI matrix rubies (2.7/3.0/3.1) the suite passes.
- **The committed `Gemfile.lock` does not install on modern Ruby**: it pins `stringio 3.0.1`,
  whose native extension fails to build on Ruby ≥ 3.2. `bundle install` fails out of the box
  on Ruby 3.3.
- **CI**: GitHub Actions matrix covers Ruby 2.7.5/3.0.3/3.1.0 on Ubuntu and macOS (note the
  stray trailing space in `'3.1.0 '`), plus a CodeQL workflow. A stale `.travis.yml` remains.
- **The gemspec declares no `required_ruby_version`** and its only runtime dependency is
  `bundler`. The bundled plugins' real dependencies (`rugged`, `octokit`, `tty-prompt`) are
  resolved lazily via inline gemfiles at plugin load time.

## Confirmed bugs

Each of these was reproduced against this checkout, not just read from the code.

### 1. `Registry#register` silently discards its block — registered commands are no-ops

`registry.rb:26` passes the block as an *option* (`options.merge(block: block)`), but
`Command#initialize` (`command.rb:42`) only honors a block passed as an actual Ruby block
(`block_given?`) and never reads `options[:block]`:

```ruby
registry.register(:greet) { |opts| puts "BLOCK RAN" }
registry.find(:greet).run   # => nothing; the command got the default empty proc
```

Every command registered through the documented `Registry#register` API does nothing when
run. The DSL path (`Configurator` → `on_run`) is unaffected, which is why the feature specs
don't catch it. Fix: `Command.new(name, registry: self, **options, &block)` or honor
`options[:block]`.

### 2. `Runner` memoizes the first plugin lookup — multi-plugin commands get the wrong object

`runner.rb:41` caches `@plugin_executor ||= ...` without keying by name:

```ruby
def plugin_executor(plugin_name)
  @plugin_executor ||= command.registry.find_plugin(plugin_name)&.executor
end
```

The first plugin referenced in an `on_run` block is returned for *every* subsequent plugin
reference. Reproduced: after resolving plugin `alpha`, a lookup for `beta` returns `alpha`'s
executor. Any command using two or more plugins — including the bundled `github` plugin,
which uses `prompt`, `github`, and `say` together — calls methods on the wrong object.
Fix: memoize in a hash keyed by `plugin_name`, e.g. `(@plugin_executors ||= {})[plugin_name] ||= ...`.

### 3. `Option#value` can't hold `false` — switches with truthy defaults can't be turned off

`option.rb:26–28`:

```ruby
def value
  @value || @default
end
```

An explicitly assigned `false` (e.g. from `--no-loud`) falls through to the default.
Reproduced: a switch with `default: true` set to `false` still reports `true`. Any boolean
switch defaulting to `true` is impossible to disable, and flags explicitly set to `nil`/`false`
silently revert. Fix: track assignment explicitly (`defined?(@value)` guard or an
`@value_set` flag).

### 4. `Option` defines `eql?` without `hash` — the options `Set` never deduplicates

`option.rb:30–36` implements `==` and aliases `eql?`, but never overrides `#hash`, so
`Set` falls back to identity. Reproduced: two equal options produce a `Set` of size 2.
`Command#options` (`command.rb:83`) therefore provides none of the uniqueness the docs
promise, and duplicate option names silently coexist (last one wins at merge time in
`Command#run`). Fix: `def hash; [self.class, name, default, description].hash; end`.

### 5. `System::Command#name` is always the empty string

`system.rb:19` splits on *word characters* instead of whitespace:

```ruby
@name = command_with_arguments.split(/\w/i).first   # "git log" → ""
```

Reproduced: the name of every system command is `""`, so `System.run` failures raise
`"<stderr>" "" failed to run.` with the command name missing. Fix: `split(/\s/)` (or
`.split.first`).

### 6. Configured log path keeps its trailing newline

`logger.rb:32` reads `` `git config --get commander.log-file-path` `` and never `chomp`s.
When the setting exists, the logger opens a file whose name ends in `\n`. Fix: `.chomp`.

### 7. `Plugin#find_command` indexes an Array as a Hash

`Plugin::Loader` assigns `plugin.commands = @commands` (an **Array**, `plugin/loader.rb:27`),
but `Plugin#find_command` does `commands[command_name.to_s.to_sym]` (`plugin.rb:38`) — a
Hash-style lookup that raises `TypeError` on an Array. The method is currently dead code,
which is why nothing crashes, but it fails the moment anyone uses it.

### 8. The bundled `github` plugin cannot work

Two independent problems in `plugins/github.rb`:

- `promt.mask(...)` (line 16) — a typo for `prompt`, so `github:setup` crashes at the
  password prompt. The same typo is reproduced in the README example (line 149), along
  with a second README-only bug (`client.user` where only `github` is in scope).
- The auth flow itself (username/password + `X-GitHub-OTP` header) was removed by GitHub in
  November 2020. Even with the typo fixed, setup cannot succeed against the real API.

### 9. Unknown-command logging always logs a blank name

In `CLI#run` (`cli.rb:30–34`), when `registry.find` raises `CommandNotFound`, the local
`command` was never assigned, so `log_command_not_found(command)` interpolates `nil` and the
log reads "` not found in registry`". The *user-facing* fallback help is fine; only the log
loses the one fact it exists to record. Fix: log `arguments.first`/the requested name instead.

## Design flaws and rough edges

Not single-line bugs, but weaknesses worth deliberate decisions:

- **`git cmd help <command>` is documented but not implemented.** The README (line 52)
  promises per-command help; the CLI has no `help` command — `git cmd help current` hits
  `CommandNotFound` and prints the *global* help. `Command#help` exists and is only reachable
  when option parsing fails.
- **Short-flag collisions.** CLI flags/switches auto-derive their short form from the first
  letter of the name (`cli.rb:104,112`). Two options starting with the same letter silently
  fight over the same `-x`.
- **`exit 1` inside `parse_command_options!`** (`cli.rb:67`) kills the host process from
  library code. Anyone embedding the CLI (or testing it) would rather see an exception
  bubble to the entry point.
- **Registered commands are stateful.** `CLI#parse_command_options!` writes parsed values
  into the `Option` objects owned by the registered `Command`, and `Command#run` merges
  them into a hash keyed by name. One-shot CLI runs mask this, but any long-lived process
  (REPL, test suite, future daemon) leaks values across runs, and options that share a name
  clobber each other.
- **All-or-nothing file loading.** `Registry#load` registers nothing if a file produced any
  error, discarding commands in that file that parsed cleanly. Reasonable as a safety
  stance, but combined with warning-level logging to a file in `/tmp`, the user experience
  is "my command vanished, silently".
- **Repo-local plugins can't be declared as dependencies.** `plugin :name` resolves symbols
  against the *bundled* plugin directory only (`plugin/loader.rb:44–46`). Plugins in
  `.git-commands/plugins/` load only via the entry-point glob — after command files —
  so a command file can't express "I need my repo's custom plugin", and load order is
  implicit. Relatedly, plugin file names containing dots truncate (`my.plugin.rb` → `my`).
- **Signature drift between the DSL and the loader.** `Raw#plugin` and `Plugin::Loader#plugin`
  forward `**options` into `Plugin::Loader#load(name)`, which accepts none — any options
  raise `ArgumentError`. Likewise `Loaders::FileLoader#load` doesn't match its parent's
  `load(options = {})` contract. Symptoms of an interface that evolved without a test on
  the seam.
- **Inline gemfiles don't install.** `Loader` requires `bundler/inline`, and plugin files
  call `gemfile { gem "rugged" }` — but without `gemfile(true)` Bundler only *activates*
  already-installed gems. On a machine without `rugged`/`octokit`/`tty-prompt` pre-installed,
  every bundled plugin fails to load. First-run experience is broken by default.
- **Duplication that has already drifted.** Help formatting lives in both `CLI#help` and
  `Command#help`; `command`/`plugin` DSL methods are near-duplicates between `Raw` and
  `Plugin::Loader`; `handle_error` is pasted into three loaders. The two help
  implementations already format differently.
- **`System.run` semantics.** `:blocking` actually means "raise on failure" (and only the
  literal `false` disables it), `:silent` gates a bare `puts` to process STDOUT — ignoring
  the `output` IO abstraction the rest of the codebase carefully threads through. The
  docstring ("Supress errors") documents the confusion rather than resolving it.
- **Housekeeping.** Stale `.travis.yml`; CI matrix entry `'3.1.0 '` with trailing space;
  `README` still says commands can be organized in "your git-root's directory" while the
  entry point only globs `Workflow` and `.git-commands/`; gemspec lacks
  `required_ruby_version` and `metadata` (e.g. `rubygems_mfa_required`); `rspec < 4.0` and
  `rake ~> 12.3` pins are dated.

## Security considerations

These are mostly inherent to the tool's design, but they deserve explicit documentation
and mitigations:

1. **Running `git cmd` in a repository executes that repository's Ruby code.** The entry
   point loads `./Workflow` and `.git-commands/**/*.rb` from the *current working directory*
   with no trust prompt. Cloning an untrusted repo and running `git cmd` (even a typo'd
   subcommand — loading happens before dispatch) executes attacker-controlled code. Tools
   with the same shape (direnv, mise) solve this with an explicit allow/trust step per
   directory; git-commander should too.
2. **Inline gemfiles extend that to the gem supply chain.** If auto-install were enabled to
   fix the first-run problem, repo-authored code could also install arbitrary gems; any
   trust mechanism needs to cover both.
3. **Predictable world-writable log path.** The default `/tmp/git-commander.log` is shared
   across users on multi-user systems and is a classic symlink-attack location. Debug-level
   logs also capture full command output (`system.rb:37–44`), which can include secrets.
   Prefer `~/.local/state/git-commander/` or `XDG_STATE_HOME`.
4. **Shell commands are interpolated strings.** `System.run` takes a single string and the
   README encourages interpolating user-supplied options into it
   (`"git log #{options[:base_branch]}.."`), so command authors get injection-prone patterns
   as the paved road. Supporting argv-array form (`Open3.capture3(*args)`) would give a safe
   default.
5. **The `github` plugin's design predates token auth** — see bug #8. Any rewrite should use
   device-flow or PAT-based auth and never prompt for passwords.

## Recommended improvements

Roughly in order of impact:

**Correctness (small, high-value fixes)**
1. Fix the five one-line bugs: pass the block through in `Registry#register`, key the
   runner's plugin memoization by name, make `Option#value` respect assigned `false`,
   implement `Option#hash`, and split `System::Command#name` on whitespace. Each fix is
   1–3 lines plus a regression spec.
2. Fix the `promt` typo (plugin *and* README) and either rewrite or remove the `github`
   plugin's password-based setup.
3. Implement `git cmd help [command]` in the CLI (or wire a built-in `help` command into
   the registry) so the documented behavior exists; replace `exit 1` with an exception
   handled by `exe/git-cmd`.

**Compatibility & release hygiene**
4. Regenerate `Gemfile.lock`, add `required_ruby_version`, extend CI to current rubies
   (3.2–3.4), delete `.travis.yml`, fix the matrix typo. The two Ruby 3.3 spec failures are
   encoding-comparison issues in feature specs and should be fixed alongside.
5. Cut an actual 0.1.0 release (or 0.2.0 with the fixes) — the gem is installable from
   source only today.

**Design**
6. Make inline gemfiles work on first run: `gemfile(true)` (with user consent — see
   security note), or vendor the bundled plugins' dependencies as proper gem dependencies.
7. Add a per-directory trust mechanism before evaluating repo-local code.
8. Make parsed option values per-invocation (duplicate the command or its options at run
   time) instead of mutating registry state.
9. Consolidate the duplicated DSL (`Raw` vs `Plugin::Loader`) and help-text formatting
   (`CLI` vs `Command`) into shared modules; unify loader `load` signatures.
10. Let `plugin :name` resolve repo-local plugins (search `.git-commands/plugins/` before
    the bundled directory), and document load order.

**Safety & ergonomics**
11. Support argv-style `system.run("git", "log", ref)` to avoid shell interpolation.
12. Rename/clarify `System.run` options (`raise_on_failure:`, `echo:`), and route its
    output through the command's `output` IO.
13. Move the default log file out of `/tmp` and `chomp` the configured path.
