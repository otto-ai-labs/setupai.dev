# Contributing to SetupAI.dev

Thanks for taking the time to contribute! Here's how to get involved.

---

## Ways to contribute

- **Report a bug** — something broke or didn't install correctly
- **Suggest a tool** — a tool you think belongs in an AI dev setup
- **Improve the docs** — clearer wording, better examples, typo fixes
- **Submit a fix** — patches to `setup.sh`, `index.html`, or `README.md`

---

## Reporting bugs

Open an issue and include:

1. Your Mac model and chip (Apple Silicon or Intel)
2. macOS version (`sw_vers -productVersion`)
3. The full error message from the log file (`~/ai-dev-setup_*.log`)
4. Which step failed (e.g. "Step 6 — AI Tools")

---

## Suggesting a tool

Open an issue with:

- What the tool does
- Why it belongs in an AI dev setup
- How to install it (brew formula, npm package, etc.)
- Whether it should be in the default install or behind a flag

---

## Submitting a pull request

1. **Fork** the repo and create a branch from `main`
2. **Make your changes** — keep them focused and minimal
3. **Test locally** — run `bash -n setup.sh` to catch syntax errors, then do a full run on a real or VM Mac if possible
4. **Open a PR** with a clear description of what changed and why

### Guidelines

- One concern per PR — don't mix a bug fix with a new feature
- Preserve the existing style: `log_info` / `log_success` / `log_warning` for all output, `|| true` error handling, timeout wrappers for brew installs
- Don't remove the `run_with_timeout` / `brew_install_with_timeout` wrappers — they exist for a reason
- If adding a new tool, add it to the right step and update the final summary block at the bottom of `setup.sh`
- Update `README.md` and `index.html` to reflect any tool additions or flag changes

### Testing checklist

- [ ] `bash -n setup.sh` passes with no errors
- [ ] No references to removed tools remain (search for tool name across all files)
- [ ] Flag names in `setup.sh`, `README.md`, and `index.html` all match
- [ ] Install command URL is identical across all three files

---

## Code style

- Shell: 4-space indentation, `#!/bin/bash` shebang
- HTML/CSS/JS: 2-space indentation
- Keep lines under 100 characters where practical
- Comments explain *why*, not *what*

---

## License

By contributing you agree that your changes will be licensed under the [MIT License](LICENSE).
