# cryogen

[![Build Status](https://travis-ci.org/anujdas/cryogen.svg?branch=master)](https://travis-ci.org/anujdas/cryogen)

`cryogen` is a tool for managing encrypted secrets in a repository. It allows
versioning of secrets alongside code within an existing VCS workflow (`git`,
etc.).  `cryogen` is heavily inspired by the Ruby tool
[Arcanus](https://github.com/brigade/arcanus) but runs as a single binary
with no external dependencies, greatly simplifying use with projects in any
language.

`cryogen` shines when working with a team on a project that requires secret
values and follows the [12-factor methodology](https://12factor.net/), reading
secrets from environment variables.

## Installation

`cryogen` is written in [Crystal](https://crystal-lang.org/), a
statically-typed, null-safe, compiled language with syntax inspired by Ruby.
Assuming you have a Crystal compiler installed (see the [Crystal
docs](https://crystal-lang.org/docs/installation/) for more information), you
should be able to build a binary by cloning the repo and running:

```bash
$ cd path/to/repo
$ make build-release
```

The resulting binary (at `bin/cryogen`) can be installed via the `make install`
command. You may need to add `/usr/local/bin` to your `$PATH` in order to make
the command available everywhere.

## Usage

`cryogen` provides built-in help that can be accessed via the `--help` flag on
any command. When executed without a specified command, the generic help is
displayed:

```bash
$ cryogen --help

Usage:
  bin/cryogen [flags...] [arg...]

A tool for managing secrets

Flags:
  --help     # Displays help for the current command.
  --version  # Displays the version of the current application.

Subcommands:
  edit       # Opens the vault in $EDITOR
  export     # Print decrypted vault contents in shell `eval`-able ENV format
  lock       # Lock the vault
  rekey      # Rotate the vault key
  setup      # Initialize a vault in this directory
  show       # Show decrypted contents of vault
  unlock     # Unlock the vault
```

### First-time Setup

Initialise a vault in a repository by using the `cryogen setup` command. This
will create an empty vault and display the secret key. *MAKE SURE* you save
this key -- without it, the vault will be inaccessible! Ideally this key will
be kept in a shared secret store, e.g., a password manager that you and your
team can access. *Do not lose it.*

*Important*: commit your vault, but do *not* commit your key! Doing so will
render the vault encryption pointless. Add the key to your `.gitignore` or
equivalent to prevent this:

```
# .gitignore
...
/.cryogen/secret.key
```

### Adding/Editing the vault

Edit the vault using `cryogen edit`. You should configure `$EDITOR` with your
favourite editor beforehand -- good choices include `nano` and `vim`. You can
add this to the bottom of your shell's rc file:

```
# ~/.bashrc, ~/.zshrc, etc.
...
export EDITOR=vim
```

Or, you can prefix the command: `EDITOR=nano cryogen edit`

Either way, you'll be greeted by your editor with the decrypted vault
displayed. Make changes in valid [YAML](http://yaml.org/) format and save +
exit when done. Note that keys and secrets _must_ be strings, since they'll be
exported as environment variables (which are untyped); however, you may nest
your YAML as deeply as you wish. One common pattern of organising secrets is to
split them by environment:

```yaml
development:
  google:
    client_id: my_client_id
    client_secret: my_client_secret
  facebook:
    api_key: my_api_key
production:
  google:
    client_id: my_real_client_id
    client_secret: my_real_client_secret
  facebook:
    api_key: my_real_api_key
```

If your YAML cannot be processed, you'll be offered the chance to fix any
issues before encryption.

### Using Secrets in your Application

`cryogen` assumes you're using [12-factor](https://12factor.net/). The `cryogen
show` command exists to check the vault contents, but for app usage, use
`cryogen export` instead. For instance, given the vault above:

```bash
$ cryogen export

export DEVELOPMENT_GOOGLE_CLIENT_ID=my_client_id
export DEVELOPMENT_GOOGLE_CLIENT_SECRET=my_client_secret
export DEVELOPMENT_FACEBOOK_API_KEY=my_api_key
export PRODUCTION_GOOGLE_CLIENT_ID=my_real_client_id
export PRODUCTION_GOOGLE_CLIENT_SECRET=my_real_client_secret
export PRODUCTION_FACEBOOK_API_KEY=my_real_api_key
```

This output is suitable for evaluation by `bash` directly, as in `eval
$(cryogen export)`. Alternatively, `cryogen export --no-subprocess` omits the
`export` prefix.

The `--only` flag allows exclusion of prefixes. For example, given the by-stage file above, one might use:

```bash
$ cryogen export --only=production

export GOOGLE_CLIENT_ID=my_real_client_id
export PRODUCTION_GOOGLE_CLIENT_SECRET=my_real_client_secret
export FACEBOOK_API_KEY=my_real_api_key
```

### Locking and Unlocking

Since your key should be ignored by your VCS, leaving a vault unlocked on your
dev machine should be fine (assuming you're using full-disk encryption and a
strong password). Nonetheless, you may wish to avoid vulnerability by removing
the key from your local disk. This is as simple as `cryogen lock` (remember to
ensure your key is stored securely first!).

When checking out a repository with a `cryogen` vault, you have two options:
you can unlock the chest for future use, or you can set the key in an
environment variable to access the chest as though it were unlocked. The former
involves running `cryogen unlock` and following the prompts, and is helpful
during development.  The latter is suitable for CI/CD, where you do not want to
store the vault alongside the key. Most commands that require a key (e.g.,
`export`) can use the `$CRYOGEN_KEY` environment variable directly, as in:

```bash
$ CRYOGEN_KEY=my_key cryogen export

# export SECRET=value
```

## Technical Details

`cryogen` uses OpenSSL bindings to encrypt each individual secret using
AES-256-CBC. The resulting ciphertext is then signed using HMAC-SHA256. The IV,
ciphertext, and signature are stored together in the encrypted vault in a
structure matching the original unencrypted vault layout.

The secret key is generated from a cryptographically secure random byte source.
256 bits are used for each of encryption and signing. The concatenated 512 bits
form the `.cryogen/secret.key` file, and a base64-encoded version is provided
to the user as a copy/paste-able key.

## Development

`cryogen` is compiled and statically typed.
- `make` will install dependencies and build a binary
- `make build-release` will do the same, but will emit a release binary
- `make clean` will remove build artifacts
- `make test` will run specs
- `make format` will format code according to the Crystal style guide

## Contributing

1. Fork it (<https://github.com/anujdas/cryogen/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [anujdas](https://github.com/anujdas) Anuj Das - creator, maintainer
