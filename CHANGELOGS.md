## Changelogs
### Changelogs v0.2
* Added the `removeComments` parameter to `readScript`.
* Fixed a bug where the value after `and`/`or` is always evaluated.
* Fixed a bug where error's line is often incorrect. (It might still be not exact)
* Fixed a bug where `;` causes an unexpected character error.
* Errors are now handled in all functions and not only in `readScript`.
* Added a fix to `table.unpack` and the `#` operator that sometimes gave wrong results. (This fixed many other bugs)
* Fixed a bug where `break` only skips the current iteration.
* Fixed bugs related to environments and nil local variables.
* Added `keepLines` parameter to `removeComments`.
