# dotfiles-bootstrap

Tiny public bootstrap for my private dotfiles repo.

## Fresh machine

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/tumpaksewu/dotfiles-bootstrap/main/bootstrap.sh)"
```

What it does:

1. Installs GitHub CLI on macOS if missing.
2. Runs `gh auth login` if needed.
3. Clones or updates the private dotfiles repo at `~/dotfiles`.
4. Executes `~/dotfiles/bootstrap`.

## Overrides

```bash
DOTFILES_REPO=tumpaksewu/dotfiles DOTFILES_DIR=~/dotfiles sh -c "$(curl -fsSL https://raw.githubusercontent.com/tumpaksewu/dotfiles-bootstrap/main/bootstrap.sh)"
```
