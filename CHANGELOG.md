# Changelog

## Rugments 1.0.0 (2015-XX-XX)

* Initial fork from [rouge](https://github.com/jneen/rouge)
* Huge code cleanup (linting with rubocop)
* Replaced AUTHORS with a generated list from git. Provided a .mailmap file as well.
* Improved HTML formatter
  * Changed `wrap` to `nowrap` which is `false` by default
  * Ported `linenos`, `linenostart`, `lineanchors` and `anchorlinenos` from pygments
  * See documentation here: http://pygments.org/docs/formatters/#HtmlFormatter
  * Added `lineanchorsid` to be able to change the url fragment
