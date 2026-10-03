<p align="center">
  <img src="https://raw.githubusercontent.com/SruSanCyborg/FINSEC_CLI_Sirus/main/media/sirus-hero.svg" width="100%" alt="Sirus by SruSan">
</p>

# Sirus, by SruSan

<p align="center">
  <img src="https://raw.githubusercontent.com/SruSanCyborg/FINSEC_CLI_Sirus/main/media/sirus-demo.gif" alt="sirus running in a terminal" width="640">
</p>

**A security and control layer for AI agents that can move money, and a compliance linter for the code they run on.**
It runs entirely on your machine: no backend, no network, no account.

## Install

Needs [Node.js](https://nodejs.org) 22 or newer.

```bash
# try it without installing
npx @srusan/sirus --help

# or install the `sirus` command globally
npm install -g @srusan/sirus
sirus --help
```

Also works with `pnpm add -g @srusan/sirus`, `yarn global add @srusan/sirus` and `bunx @srusan/sirus`.

## Quick start

```bash
sirus              # interactive shell
sirus init         # scaffold sirus.yaml in your project
sirus scan .       # scan the current project for money-handling risks
sirus guard        # decide, per action, whether an agent's transaction should happen
sirus revenue gen  # generate a sample batch, then detect / eval / recover / audit
sirus doctor       # check your setup
```

Every command has `--help`. The full documentation, demo video and design notes are on
[GitHub](https://github.com/SruSanCyborg/FINSEC_CLI_Sirus).

## Author

Made by **Sanjay Sivakumar** ([SruSan](https://github.com/SruSanCyborg)) ·
[LinkedIn](https://www.linkedin.com/in/sanjaysivakumar11/) · MIT licence.
