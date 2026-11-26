---
name: odoo-pr-review
description: Review an Odoo pull request, branch, commit, or local diff against Odoo's official house rules (odoo-guidelines, odoo-web-guidelines, odoo-security, odoo-git) plus a sceptical merits pass. Use when asked to "review this PR", "review my diff", "check my branch before PR", "self-review", "is this ready to merge", or given an odoo/odoo or odoo/enterprise PR link or number, even if the user does not say "Odoo review" explicitly.
---

# Odoo PR Review

Goal: find what an Odoo reviewer would block on, before they see it. Every finding
points to a line, says how it fails, and gives a fix.

This is the only review skill in the plugin. It runs Odoo's official review process,
kept in `references/odoo-review-process.md` (a copy of the community
`odoo-review` skill with sibling paths adjusted), and adds the reviewer patterns and team checklist on top. The house
rules it applies are Odoo's official guideline skills, bundled next to this one.

## Step 1: Know the rule files

All paths are relative to this skill's base directory.

| File | Covers |
| --- | --- |
| `references/odoo-review-process.md` | the review process itself: scope, map, read, rules pass, merits pass, report. Its own links (`../../odoo-guidelines/...`) are relative to the `references/` folder |
| `../odoo-guidelines/SKILL.md` + `guidelines/*.md` | every addon file outside `static/` |
| `../odoo-web-guidelines/SKILL.md` + `guidelines/*.md` | JS, Owl templates, SCSS, hoot tests under `static/` |
| `../odoo-security/SKILL.md` | controllers, `ir.access`, `sudo()`, raw SQL, `eval`, public/RPC methods |
| `../odoo-git/SKILL.md` | commit message format, target branch, PR hygiene |

They are a copy of `community/skills/` taken at the revision in `../../UPSTREAM_SKILLS_REV`.
If the community checkout under review has a `skills/` folder at a newer revision, prefer
that one and say so in the report. Refresh the bundled copy with
`../../scripts/sync-odoo-skills.sh <path-to-community>`.

## Step 2: Run the official review

Read `references/odoo-review-process.md` and follow it exactly: scope, map, read, rules pass, merits pass, report.
It defines the process and when the review is complete; do not shorten it.

Points to keep in mind while following it:

- **Rules come from master, code may not.** The guidelines describe master. For a
  stable target (`17.0`, `18.0`, `saas-*`), the existing file style wins, and
  `odoo-guidelines/guidelines/stable.md` applies to every file. Before flagging an API
  as wrong or missing, confirm it at the revision under review (`git grep`), not in the
  guidelines' examples.
- **Commit messages.** Check every commit of the PR against `odoo-git/SKILL.md`.
- **Security.** Any controller, `sudo()`, raw SQL, `eval`, `Markup`, or new
  public/RPC method gets the matching section of `odoo-security/SKILL.md`.
- **Reviewer patterns.** After the official rules pass, read
  `references/review-patterns.md` (next to this file) if it exists. It lists deprecated APIs with
  the version they disappear in, plus the nitpicks and idioms Odoo reviewers keep
  asking for that the official guidelines do not spell out. Check the diff against
  the sections that match the changed files and cite them as *review pattern*. A
  deprecation counts as a finding only if the target branch has the replacement:
  check its row in the table and `git grep` when unsure.
- **Team checklist.** If the `reviewdoo` MCP server is available, call its
  `get_review_checklists` tool and apply the items that match the changed modules,
  citing them as *team checklist*.

## Step 3: Report

Use the report format from `references/odoo-review-process.md`. Order findings most severe first,
and tag each one:

- `blocker`: bug, security hole, data loss, stable-version rule broken.
- `major`: performance at scale, missing test, wrong API, wrong scope.
- `minor`: naming, clarity, comment.

Close with the **Guidelines read:** line the official skill asks for, the revision the
rules were read from (working tree or `odoo/master@<short sha>`), and a one-line verdict:
ready / ready after fixes / needs rework.

Flag problems; edit code only when the user asks for fixes.
