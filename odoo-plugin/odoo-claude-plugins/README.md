# odoo-claude-plugins

Claude Code plugin marketplace for Odoo development. It holds one plugin,
[`odoo-dev-kit`](plugins/odoo-dev-kit/README.md): spec clearance, PR review against
Odoo's official guidelines, and feature testing.

## Quick install

From a clone or copy of this folder:

```bash
claude plugin marketplace add /path/to/odoo-claude-plugins
claude plugin install odoo-dev-kit@odoo-claude-plugins
```

From a git repository whose root is this folder:

```bash
claude plugin marketplace add <github-owner>/<repo-name>
claude plugin install odoo-dev-kit@odoo-claude-plugins
```

Restart Claude Code, then ask for example `review my branch before I open the PR`.
See [plugins/odoo-dev-kit/README.md](plugins/odoo-dev-kit/README.md) for every skill,
updating, and removing.
