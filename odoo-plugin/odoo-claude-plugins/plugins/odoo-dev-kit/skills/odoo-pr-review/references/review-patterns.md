# Recurring review patterns

Distilled from real odoo/odoo review comments; complements the bundled
guidelines (`odoo-guidelines`, `odoo-web-guidelines`, `odoo-security`,
`odoo-git`) and does not repeat them.

## Contents

- [Deprecated and removed APIs](#deprecated-and-removed-apis)
- [Python and ORM](#python-and-orm)
- [XML and views](#xml-and-views)
- [JavaScript and Owl](#javascript-and-owl)
- [Tests](#tests)
- [Translations and strings](#translations-and-strings)
- [Naming and nitpicks](#naming-and-nitpicks)
- [Commits and PR hygiene](#commits-and-pr-hygiene)

## Deprecated and removed APIs

Checked with `git grep` against `odoo/18.0` and `odoo/master`. "gone" = no
definition left; "deprecated" = still works but emits a warning. Flag an old
API by the branch the PR targets, not by memory.

| Old | Replacement | 18.0 | master |
|-----|-------------|------|--------|
| `attrs=` / `states=` in views | plain `invisible=` / `readonly=` / `required=` expressions | gone (view validation error since 17.0) | gone |
| `<tree>`, view type `tree` | `<list>`, view type `list` | gone (renamed) | gone |
| `name_get()` | `_compute_display_name()` | gone | gone |
| `_name_search()` | `_search_display_name(operator, value)` | gone | gone |
| `fields_view_get()` | `get_view()` / `get_views()` | gone | gone |
| `user_has_groups()` | `self.env.user.has_group()` / `has_groups()` | gone | gone |
| `check_access_rights()` / `check_access_rule()` | `check_access(op)` (raises) / `has_access(op)` (bool) | deprecated | gone |
| `fields.X(group_operator=...)` | `aggregator=` | deprecated (aliased) | gone |
| `_sql_constraints = [...]` | `models.Constraint` / `models.Index` / `models.UniqueIndex` attributes | only API | ignored, setup warning |
| `odoo.tests.common.Form` | `odoo.tests.Form` | deprecated | gone |
| `odoo.osv.expression` (`AND`, `OR`, `normalize_domain`) | `odoo.fields.Domain` (`&`, `\|`, `~`) | only API (no `Domain`) | gone (`odoo/osv` removed) |
| `self._cr` / `self._uid` / `self._context` | `self.env.cr` / `self.env.uid` / `self.env.context` | alias property | gone |
| `read_group(domain, fields, groupby, lazy=)` | `_read_group(domain, groupby, aggregates)`; `formatted_read_group` (web, master only) | old signature | `read_group` takes the `_read_group` signature, returns tuples |
| `ir.config_parameter` `get_param` / `set_param` | `get_str` / `get_bool` / `get_int` / `get_float`, `set_*` | only API | gone |
| QWeb `t-esc` | `t-out` | deprecated (dev-mode warning) | gone |
| `useService(...)` for what became a plugin | `usePlugin(XPlugin)` from `@odoo/owl` | n/a (no `usePlugin`) | services migrating to plugins |

Pointers: `_()` vs `self.env._()` is in odoo-guidelines `python.md`; Owl 2
hooks vs Owl 3 in odoo-web-guidelines `javascript.md`; `t-raw` in odoo-security.

## Python and ORM

- **Test membership against a set literal.** Reviewers flag tuples every time.
  `if move.move_type in ('out_refund', 'in_refund')` -> `in {'out_refund', 'in_refund'}`
- **No `elif`/`else` after a branch that returns, raises or continues.** Flat is easier to read.
- **Inline a variable used once, only for a comparison.**
  `code = tree.findtext(path)` + `if code == '262'` -> `if tree.findtext(path) == '262':`
- **Set several fields with one `write()`, and keep it multi-record.** A chain of
  assignments makes one write per field, and `self.x = ...` blocks batch callers.
  `self.a = False; self.b = False` -> `self.write({'a': False, 'b': False})`
- **"Today" for a user means `fields.Date.context_today(record)`.** `Date.today()`
  is the server's UTC date, so it is off by a day in other timezones.
- **Do not pass a default argument again.** For example, `currency._convert(...)`
  already defaults `date` to today, so `fields.Date.today()` is noise.
- **Format dates with `odoo.tools.format_date` / `format_datetime`.** Calling
  `strftime('%b %-d')` takes the server locale, not the user's language.
- **Do not call computes by hand.** If you see `rec._compute_x()`, `_fields['x'].compute_value(...)`
  or `flush_recordset([...])` written to make a value appear, fix `@api.depends`.
- **Drop `@api.depends` entries the compute no longer reads.** Extra triggers
  cost recomputes (missing ones: see odoo-guidelines `orm.md`).
- **`related=` fields are already readonly.** Without an inverse, `readonly=True` is redundant.
- **Watch new stored columns on big tables.** A `default=` or a stored compute
  on `account.move(.line)`, `stock.move` and similar tables fills every
  existing row at install. Drop the default when code already falls back to it,
  or create and fill the column in a `pre_init_hook` before the ORM computes it.
- **`browse(id)` from client input needs `.exists()` before reading.**
  Without it you get a `MissingError`, not the intended branch. `env.ref()` already checks.
- **Fail loudly on what must exist.** Use `.get()` and `raise_if_not_found=False`
  only when absence is a legitimate case. Otherwise they hide ordering bugs.
- **Do not accumulate recordsets with `|=` in a loop.** Collect ids, then `browse()`
  once, or collect records and call `union(*records)`.
- **Hoist loop-invariant work.** This covers heavy per-calendar or per-company
  calls, and lookups such as `_get_translatable_fields()`. Group them by key and call once.
- **Put the guard in the callee.** When every caller checks a context key or a
  config before calling `_check_x()`, move that check inside `_check_x()`.
- **Mark a method `@api.model` when it does not use `self`'s records.** A method
  reached from `@api.model` code can run on an empty recordset, so it must not read `self`.
- **Use `self.env.user._is_system()`, not `has_group('base.group_system')`.**
- **Use a targeted `sudo()`.** Read the one field under sudo, not
  `self.browse(ids).sudo()` on a whole batch. See odoo-security for the rule.
- **Do not detect other modules at runtime in master.** `'field' in self._fields`
  and `'model' in self.env` belong in a bridge module override. Accept them in stable only.
- **Prefer explicit parameters to `**kwargs`.** If kwargs stay, document them in the docstring.
- **Use stdlib `urllib.parse` over the monkey-patched `werkzeug.urls`.**
- **Wrap long chains in parentheses, one call per line, not with backslashes.**
- **Split long string literals with implicit concatenation, one per `\n`.**
- **Replace nested lambdas with a named function or a loop.**
- **Use `# noqa` only for a lint code the line actually triggers.**
- **Give a new model a class docstring.** Say what it represents and who uses it.

## XML and views

- **Combine a condition instead of replacing it.** Other modules may extend the same attribute.
  ```xml
  <xpath expr="//tr[@name='line']" position="attributes">
      <attribute name="t-if" add="not line.get('is_deposit')" separator="and"/>
  </xpath>
  ```
- **Do not rewrite a core `domain`/`context` in an inheriting view.** Your copy
  hides every later change upstream. Restrict in Python, or in a constraint.
- **Remove no-op attributes:**
  - `expand="0"` on a search `<group>`;
  - `readonly` on an element that is invisible in that state;
  - an unused `context=`;
  - CSS classes that no rule targets;
  - `t-attf-class` with nothing to interpolate (use `class`).
- **QWeb omits a `t-att-x` attribute whose value is `False`.** No `t-if` is
  needed to skip `data-*` for an empty record. Use `t-att-data-id="wish.id"`.
- **Use a nested `<group>` for label/field layout** instead of custom classes
  or splitting `<label>` from `<field>`.
- **Add to the module's existing view and view file.** Do not create a second
  file or inherit a view the module already owns. Do not repeat an xpath for the
  same target in one file.
- **Re-indent wrapped content** when you add a parent element. Prefer changing
  a tag (`div` to `nav`) over adding a wrapper that re-indents a whole block.
- **Remove wrappers with one child** (`d-flex` around one element) and dead layout divs.
- **XPath should match one node.** Repeated ids in a report match several nodes,
  and only the first is used. Anchor on a distinctive attribute (see odoo-guidelines `xml.md`).
- **Share asset lists with `('include', 'module.bundle_name')`.** Do not copy
  another app's file globs into your manifest.
- **Do not save on render.** A widget editable in readonly mode must save its change itself.
  `record.update(vals, {save: !record.isInEdition})` in versions that still have the option.

## JavaScript and Owl

- **The template name matches the component class.**
  `static template = "mrp.ForecastWidget"` for `ForecastWidget`.
- **Mark a function `async` when it awaits or returns a promise.**
- **Use absolute imports in tests.** Write `@mail/../tests/mail_test_helpers`,
  not `../mail_test_helpers`. Keep the import block sorted.
- **Master: read plugins with `usePlugin`, not `this.env.services[...]`.**
  Drop the `Service` suffix from fields that now hold a plugin.
- **Keep side effects out of render.** `onWillRender` and templates must not
  create or change records. A screen should not branch on the current route.
- **Do not `await` slow or third-party calls in `onWillStart`.** Render a
  placeholder, load in the background, and add a timeout.
- **A failing RPC in shared setup (`??= await rpc(...)`) takes the whole app down.**
  Catch it or move it next to its only user.
- **Boolean names hold booleans.** `const isCombo = tmpl.combo_ids?.length > 0;`
  not `?.length`.
- **Drop optional chaining on a value already checked**, because it hides real bugs.
- **No backward-compatibility branches in master.** Remove old argument shapes
  so that callers migrate.
- **Encode an invariant as a condition, not as a comment.**
  `// queue is empty here` -> `if (!this.queue.length) { ... }`
- **Check RTL.** Code that sorts or positions with `offsetLeft`, `left` or
  `right` must also work in RTL languages.
- **Accessibility:**
  - use `inert` rather than `tabindex="-1"` plus `pointer-events: none`;
  - images get `alt` (and `title` when useful);
  - an `aria-label` carries the full visible context ("Preset 2, Secondary, Low contrast").
- **Show units next to quantities when UoM can differ.** Show UoM only when the
  UoM feature is enabled.
- Formatting such as `if (`, double quotes and one blank line after imports is
  eslint's job (see odoo-web-guidelines `javascript.md`).

## Tests

- **No `try/except` in a test.** If it must raise, use `assertRaises`; if it
  must not, let it raise. `TransactionCase` already clears commit hooks.
- **Assert the precondition before the action.** Assert that it is not already
  so before asserting that it became so.
- **A test must fail without the fix.** Drop tests that check a plain write
  sticks, or that a hard-coded template contains its own string.
- **Mock at the external boundary.** Patch the lowest call (the HTTP/API
  transaction), then assert the record state, not the mock's call args.
- **Use `RecordCapturer(model)` to get the records the action created.** Do not
  `search()` for them afterwards. The domain argument is often unnecessary.
- **Cover the entry point the user hits** (`action_*()` of the button), not
  only the helper or route. Add the negative case.
- **Use `Form.from_action(env, action)` to drive wizards opened by an action,**
  and `assertRecordValues` to check several fields at once.
- **Do not restore config parameters or data at the end.** The test transaction rolls back.
- **Call `env.flush_all()` before raw SQL in a test**, or the query reads stale rows.
- **Access tests run as a restricted user.** The superuser passes every check,
  so a test run as it proves nothing. Do not grant the test user extra groups
  to make it pass: the code must sudo, or the user must have the right.
- **Add the case to the existing file or class that has the setup.** Do not
  duplicate a test that already exists. Keep one feature per test.
- **`mute_logger` only when the log is expected and unavoidable.** When the
  warning reveals a real defect, fix that defect and drop the mute.
- **Freeze time only when the test needs it, and say why.** See odoo-guidelines `tests.md`.
- **Write the docstring about the behaviour the fix guarantees,** not the setup.
- **Hoot:**
  - drop `animationFrame()` waits that nothing needs;
  - anchor selectors on the module's own class with `:count(1)`;
  - use `waitForNone(sel)` rather than re-checking what earlier steps proved.
- **Do not edit an existing test to fit new behaviour without explaining why** in the commit message.

## Translations and strings

- **Translate whole sentences.** Do not inject a translated or raw fragment.
  `_("successfully %s", action)` -> `_("E-waybill sent.")`
- **Name every placeholder.** The full rule is in odoo-guidelines `python.md`.
  `_("TIN %(tin)s found and set", tin=tin)`
- **Write a sentence a translator understands out of context.** Avoid
  "X: a (min b)" shorthand.
- **Use Title Case for `string=` of fields, groups and sections.** Changing the
  case later forces a retranslation in every language.
- **Reuse the business term already used across apps.** For example, "Credit
  Note", not "Refund". Use one label shape everywhere ("Add line" vs "Line").
- **Make error and log messages actionable.** Say what is wrong and how to fix
  it, such as "pay each vendor separately" or "reset the sync".
- **Pick the right severity.** A blocking failure is an error notification, not a warning.
- **Visitor-facing pages use `self.env.lang`.** Use the partner's `lang` only
  for documents sent to that partner.

## Naming and nitpicks

- **Suffix a sudo'ed record with `_sudo`.** `company_sudo = company.sudo()...`
- **Use full words for loop variables.** `for payment in self`, not `pay` or `x`.
  `for lang, html in translations.items()`, not `key, value`.
- **Name a Many2one after its comodel.** A field to `account.account` ends in
  `_account_id`.
- **Fields of the module's own model need no module prefix.** `l10n_xx_` belongs
  on fields added to other modules' models. Then `_rec_name` usually goes too.
- **Method names say what the method does.** `_toggle_wish` vs `_set_wish`.
  `validate` vs `check` when absence is accepted. Rename it, and update its
  docstring, when the behaviour changes.
- **Keep the prefix of a family of methods.** `_import_cii_*`.
- **A dict is not "json".** Name and document the returned type.
- **Remove dead code in the same PR:**
  - unused constants and regexes;
  - fields nobody reads;
  - service fields replaced by something else;
  - views kept for one removed use.
- **Do not add `# -*- coding: utf-8 -*-` or a per-file license header** to new Python files.
- **Do not delete docstrings while moving code.** Keep and update them.
- **Order controllers predictably:** new routes, their helpers, overridden routes,
  then overridden helpers. Model body order is in odoo-guidelines `python.md`.
- **Keep sorted lists sorted.** This covers `.weblate.json` and alphabetical test methods.

## Commits and PR hygiene

- **Move or rename files in a separate commit** so git keeps history and the
  diff stays reviewable.
- **Mention every behaviour change in the commit message.** That includes side
  fixes and dropped cases. Remove an unrelated change, or justify it.
- **Fix a bug where it lives.** A bug in a shared module (for example
  `l10n_account_withholding_tax`) is fixed there, in its own commit. Do not
  patch it in one localization with a country check.
- **Removing a state, constraint or field in master needs an upgrade script.**
  This includes a changed unique index. Data migrations must not overwrite
  values users corrected by hand.
- **Community code must not call enterprise-only methods.**
- **A stable workaround that master should drop says so** (see odoo-guidelines
  `comments.md` and `stable.md`).
- **Perf benchmarks and populate data must earn their place.** Do not add a
  blueprint for every single fix.
- The commit header scope is the module, not a platform such as "mobile". Use
  the imperative, and keep the original title on forward-ports. See odoo-git.
