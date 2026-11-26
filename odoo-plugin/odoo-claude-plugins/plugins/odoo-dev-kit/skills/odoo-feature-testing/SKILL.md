---
name: odoo-feature-testing
description: Test an Odoo feature or fix end to end - write or run Python unit tests, HttpCase tours, and a manual functional check. Use when asked to "test this feature", "write tests for", "run the tests", "add a tour", "check my fix works", "is my change covered", or after implementing an Odoo change, even if the user only says "verify it".
---

# Odoo Feature Testing

Goal: prove the feature works and keeps working. Every behaviour in the spec or fix
has at least one automated test that fails without the change and passes with it.

## Inputs

- The feature or fix: diff, branch, task description, or spec.
- Module(s) touched and the target version.
- A test database name, if the user has one.

## Process

1. **List the behaviours to prove.** From the spec or diff, write a short list:
   happy path, edge cases (empty, zero, negative, multi-company, multi-currency,
   access rights of a non-admin user), and the exact bug scenario for a fix.
2. **Find existing tests first.** Look in `<module>/tests/`. Extend an existing test
   class and reuse its setup (`setUpClass`, common classes like `AccountTestInvoicingCommon`,
   `TestSaleCommon`, `ValuationReconciliationTestCommon`) instead of building data from scratch.
3. **Pick the test type.**
   - `TransactionCase` - business logic, computes, constraints. Default choice.
   - `Form(...)` from `odoo.tests` - onchange behaviour as a user sees it in a form.
   - `HttpCase` + tour (`static/tests/tours/*.js`) - UI flow, JS widgets, website/portal.
   - `@users('...')` / `with_user()` - access rights.
4. **Write the tests.**
   - Tag them: `@tagged('post_install', '-at_install')` for anything needing all modules;
     tours always run post_install.
   - Register new files in `tests/__init__.py`.
   - Assert values, not only "no crash": `assertRecordValues`, `assertEqual`.
   - For a fix, check the test fails on the code before the fix (stash the fix and run).
5. **Run them.**
   ```bash
   ./community/odoo-bin -d <db> --addons-path=community/addons,enterprise \
     -i <module> --test-tags /<module>:<TestClass>.<test_method> \
     --stop-after-init --log-level=test
   ```
   Use `-u` instead of `-i` on an existing DB. For a flaky test, run it several times in
   parallel with `./run_odoo_tests_parallel.sh -d <db> -t <test_tag> -n 3` if the
   script exists in the workspace.
6. **Manual functional check** (when there is UI): give the user short click-path steps
   to reproduce in the browser, with the expected result for each step.

## Output

- The test code added or changed, with file paths.
- The exact command(s) run and their result (pass/fail counts, failing test names and
  the shortest decisive error line).
- Behaviours from step 1 that still have no test, and why.

## Rules

- Never claim tests pass without running them. If you cannot run them (no DB, no
  Postgres), say so and give the command.
- Do not weaken an assertion to make a test pass; find the cause.
- Keep tests independent: no reliance on data created by another test method.
