# Cryogen Changelog

## 1.2.3 (Unreleased)

* Switched to Crystal 0.27.0 language and compiler

## 1.2.2

* Only change secrets that were actually modified, to prevent vault churn and
  produce meaningful diffs

## 1.2.1

* Handle input prompt better (loop until input provided)
* Preserve original formatting on valid multiline string secrets

## 1.2.0

* Make multiline values work correctly when exported

## 1.1.0

* Added `show_key` subcommand for displaying key to an unlocked vault
* Added statically linked binary build support
* Added minimal Docker build process and image

## 1.0.0

* Initial release!
