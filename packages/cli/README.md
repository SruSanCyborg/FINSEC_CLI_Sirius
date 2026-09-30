# Sirius, by SruSan

<p align="center">
  <img src="https://raw.githubusercontent.com/SruSanCyborg/FINSEC_CLI_Sirius/main/media/sirius-demo.gif" alt="sirius running in a terminal" width="640">
</p>

**A security and control layer for AI agents that can move money, and a compliance linter for the code they run on.**
It runs entirely on your machine: no backend, no network, no account.

## Install

Needs [Node.js](https://nodejs.org) 22 or newer.

```bash
# try it without installing
npx @srusan/sirius --help

# or install the `sirius` command globally
npm install -g @srusan/sirius
sirius --help
```

Also works with `pnpm add -g @srusan/sirius`, `yarn global add @srusan/sirius` and `bunx @srusan/sirius`.

## Quick start

```bash
sirius              # interactive shell
sirius init         # scaffold sirius.yaml in your project
sirius scan .       # scan the current project for money-handling risks
sirius guard        # decide, per action, whether an agent's transaction should happen
sirius revenue gen  # generate a sample batch, then detect / eval / recover / audit
sirius doctor       # check your setup
```

Every command has `--help`. The full documentation, demo video and design notes are on
[GitHub](https://github.com/SruSanCyborg/FINSEC_CLI_Sirius).

## Author

Made by **Sanjay Sivakumar** ([SruSan](https://github.com/SruSanCyborg)) ·
[LinkedIn](https://www.linkedin.com/in/sanjaysivakumar11/) · MIT licence.
