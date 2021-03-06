# Changelog

## Rugments 1.0.0 (2015-XX-XX)

* Initial fork from [rouge](https://github.com/jneen/rouge)
* Huge code cleanup (linting with rubocop)
* Replaced AUTHORS with a generated list from git. Provided a `.mailmap` file as well.
* Use a cache for all the lexers. If you just want to use one lexer Rugments
  does not have to load all the lexers. Use `Rugments::Lexer.find_by_name` to
  get a lexer class.
* Ignore case when filtering lexers against filenames.
* Provide continuous integration support using [travis](https://travis-ci.org/rumpelsepp/rugments)
  and [coveralls](https://coveralls.io/r/rumpelsepp/rugments).
* New HTML formatter
  * Changed `wrap` to `nowrap` which is `false` by default
  * Ported `linenos`, `linenostart`, `lineanchors` and `anchorlinenos` from pygments
  * See documentation here: http://pygments.org/docs/formatters/#HtmlFormatter
  * Added `lineanchorsid` to be able to change the url fragment
