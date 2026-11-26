# odoo-dev-kit

Claude Code plugin with skills for the Odoo development workflow: challenge a
specification against standard Odoo, review a pull request against Odoo's official
guidelines, and test a feature.

## Skills

| Skill | Use it to | Example prompt |
| --- | --- | --- |
| `odoo-pr-review` | review a PR, branch, commit or local diff. The only review skill: runs Odoo's official review process, then reviewer patterns and the team checklist | `review my branch before I open the PR` |
| `spec-clearance-with-odoo-product` | fit-gap a client specification against standard Odoo before development | `clear this spec against Odoo 18: specs/client.md` |
| `odoo-feature-testing` | write and run unit tests and tours for a feature or fix | `write tests for my fix in sale_stock and run them` |
| `odoo-guidelines` | house rules for Python, ORM, XML, security files, tests | used by `odoo-pr-review`; also when writing addon code |
| `odoo-web-guidelines` | house rules for JS, Owl, SCSS under `static/` | used by `odoo-pr-review`; also when writing web code |
| `odoo-security` | security audit of addon code | used by `odoo-pr-review`; also `is this sudo() safe?` |
| `odoo-git` | commit message format, target branch, PR hygiene | used by `odoo-pr-review`; also when writing a commit |

Skills start on their own when a request matches. To call one by name, type
`/odoo-dev-kit:<skill-name>` in Claude Code, for example `/odoo-dev-kit:odoo-pr-review`.

## Install

Requires Claude Code (`claude --version`). Run these in a normal terminal, not inside
Claude Code. Restart Claude Code after installing.

### On this machine (the one that has the folder)

```bash
claude plugin marketplace add /home/odoo/odoo18/odoo-plugin/odoo-claude-plugins
claude plugin install odoo-dev-kit@odoo-claude-plugins
```

### On another machine, from a git repository

Push the `odoo-claude-plugins/` folder as the root of a git repository first
(it must contain `.claude-plugin/marketplace.json` at its top level). Then on each machine:

```bash
# GitHub repository
claude plugin marketplace add <github-owner>/<repo-name>
# or any git URL
claude plugin marketplace add https://github.com/<github-owner>/<repo-name>.git

claude plugin install odoo-dev-kit@odoo-claude-plugins
```

A private repository works if `git clone` of it works on that machine.

### On another machine, from a copied folder

Copy `odoo-claude-plugins/` anywhere, then:

```bash
claude plugin marketplace add /path/to/odoo-claude-plugins
claude plugin install odoo-dev-kit@odoo-claude-plugins
```

### Try it for one session, without installing

```bash
claude --plugin-dir /path/to/odoo-claude-plugins/plugins/odoo-dev-kit
```

### From inside Claude Code

The same steps work as slash commands:

```
/plugin marketplace add /path/to/odoo-claude-plugins
/plugin install odoo-dev-kit@odoo-claude-plugins
```

## Check, update, remove

```bash
claude plugin list                                        # is it installed and enabled?
claude plugin details odoo-dev-kit@odoo-claude-plugins    # skills it ships
claude plugin marketplace update odoo-claude-plugins      # pull the latest marketplace
claude plugin update odoo-dev-kit@odoo-claude-plugins     # install the new version
claude plugin uninstall odoo-dev-kit@odoo-claude-plugins
```

Claude Code updates a plugin only when its `version` in `.claude-plugin/plugin.json`
changes, so bump it with every change you want others to receive.

## Refreshing the bundled Odoo guidelines

`odoo-guidelines`, `odoo-web-guidelines`, `odoo-security` and `odoo-git`, and the review
process in `skills/odoo-pr-review/references/odoo-review-process.md`, are copies of
`skills/` in the Odoo community repository. The revision is in `UPSTREAM_SKILLS_REV`.
Do not edit them by hand; refresh them with:

```bash
./scripts/sync-odoo-skills.sh /path/to/community               # from odoo/master
./scripts/sync-odoo-skills.sh /path/to/community odoo/master   # explicit git ref
```

Then bump `version` in `.claude-plugin/plugin.json`.

## Adding a skill

Create `skills/<skill-name>/SKILL.md` with `name` and `description` frontmatter,
bump `version`, and check the plugin with:

```bash
claude plugin validate /path/to/odoo-claude-plugins/plugins/odoo-dev-kit
```

The bundled Odoo skills come from the Odoo community repository and keep its license.
