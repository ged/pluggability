# Release History for pluggability

---
## v0.8.0 [2022-12-01] Michael Granger <ged@faeriemud.org>

Improvements:

- Change default Ruby to 3.1
- Fix support for classes with number in their name


## v0.7.0 [2020-02-05] Michael Granger <ged@faeriemud.org>

Improvements:

- Updated for Ruby 2.7


## v0.6.0 [2018-03-12] Michael Granger <ged@FaerieMUD.org>

Bugfix:

- Switch back to require for loading derivatives


## v0.5.0 [2018-01-19] Michael Granger <ged@FaerieMUD.org>

Enhancements:

- Update the mechanism used to search for derivatives for more-modern Rubygems,
  Bundler, etc.


## v0.4.3 [2015-03-04] Michael Granger <ged@FaerieMUD.org>

Bugfix:

- Add a workaround for older Rubygems to avoid Bundler problems.


## v0.4.2 [2015-03-04] Michael Granger <ged@FaerieMUD.org>

Bugfixes:

- Set the minimum Rubygems version for #find_latest_files support [#1].


## v0.4.1 [2015-03-03] Mahlon E. Smith <mahlon@martini.nu>

Bugfix:

- Only consider the latest versions of each installed gem
  when finding files to load for .load_all.


## v0.4.0 [2014-01-08] Michael Granger <ged@FaerieMUD.org>

- Add a name attribute to plugins for introspection.


## v0.3.0 [2013-09-25] Michael Granger <ged@FaerieMUD.org>

- Add plugin exclusion patterns


## v0.2.0 [2013-03-28] Michael Granger <ged@FaerieMUD.org>

- Fix loading of grandchildren of plugins
- Rename Pluggability::FactoryError to 
  Pluggability::PluginError (with backward-compatibility aliases)


## v0.1.0 [2013-03-27] Michael Granger <ged@FaerieMUD.org>

- Add loading via underbarred name variants (CommaDelimitedThing ->
  comma_delimited)
- Rename some stuff for consistency.

## v0.0.2 [2012-08-13] Michael Granger <ged@FaerieMUD.org>

Simplify Pluggability#derivatives.


## v0.0.1 [2012-08-03] Michael Granger <ged@FaerieMUD.org>

First release after renaming from PluginFactory.

