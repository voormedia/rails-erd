1.5.2
-----
  * Disable calls to `eager_load_namespaces` < Rails 5 (#263)

1.5.1
-----

* Improved < Ruby 2.3 support (#239)
* Squashed once and for all the horizontal vs vertical orientation bugs (#241)
* Added option for specifying spline types (#242)
* Added a check for Graphviz installation before building out object graph (#248)
* Fixed a bug in auto-generation rake task (#252)
* `--cluster` option will work more reliably now! (#253)
* Because it is 2017, we added Rails 5 to our official test matrix (#254)
* Fixed a bug in `--only` that prevented it from working reliably (#257)
* Added eager loading across all namespaces in the app (#258)
* Minor improvements to tests (#228)

1.5.0
-----
* New option of 'clustering' by namespace (#205)
* Support for 'only_models_include_depth' option (#219)
* Added basic support for non-Rails apps (#208)
* Avoid duplicate specializations when using STI with an abstract base class (#211)
* Fixed Ruby 2.1 deprecation warnings (#209)
* Fixes to tests (#210, #213)
* Various documentation fixes (#203, #212)

1.4.7
-----
* Fixed grouping of associations (#190)
* Fixed issue with command line options (#198)
* Fixed horizontally graph when vertical was wanted and viceversa (#183)

1.4.6
-----
* Revert auto-generation of diagrams added in #176 (#191)
* Fix some Ruby warnings (#187)
* Rescue from TypeError when loading target app (#185)

1.4.5
-----

* Fix bug in `auto generate diagram` (#176)
* Protect against `nil` model names (#177, #178)

1.4.4
-----

* Return nil if native_type is geography (#168)
* Change tests to address flickering failures on Travis-CI

1.4.3
-----

* Fix for bug where defaults were overriding configuration options (#166)

1.4.2
-----

* Fix for issue with strings vs symbols in options (#157)
* Fix for 'geometry' columns causing errors (#158)

1.4.1
-----

* Improved travis-ci testing
* Improved speed of Attribute#from_model (#145)
* Fixed a long-standing bug in rake task (#149)
* Fixed 'No entities found' error when using filter (#152)
* Prevent deprecation warning by specifying test order (#153)
* Updated CODE_OF_CONDUCT

1.4.0
-----

* Drop support for spaces in filenames (#123)
* Ensure that #generalized? could be used (#127)
* Fixing typos in font config (#140)

1.3.1
-----

* Check that models are not abstract (#47)
* Added MIT license (#117)
* Fixed an issue with :only and :exclude options (#122)
* Added a :sort option to preserve original attribute order (#126)
* Mark primary and unique keys as such in diagram (#129)

1.3.0
-----

* Added support for Rails 4 (Issues #120, #115, #85, #89, and #68)

1.2.2
-----

* Fixes a bug in sorting abstract classes (Issues #54, #88)

1.2.1
-----

* Fixes a bug in OS detection for JRuby (and newer MRI Rubies, too)

1.2.0
-----

* Fixed bug that prevented generation of diagrams on newer versions of OSX
* Added ability to store CLI configuration options in a config file, both a global version (in the user's home directory) as well as a per-project local versions
* Added a Code of Conduct for the project

1.1.0
-----

* Abstract models (with 'self.abstract_class = true') are now considered for
  the domain and will be displayed if 'polymorphism=true'. This should also
  fix errors that could occur if abstract models had any associations.
* Correctly save Graphviz diagrams with spaces in the filename (contributed by
  Neil Chambers).
* Add only/exclude to CLI (contributed by Dru Ibarra).


1.0.0
-----

* The internal API is now stable and will be backwards compatible until
  the next major version.
* Added experimental command line interface (erd). The CLI still requires a
  Rails application to be present, but it may one day support other kinds of
  applications.
* Crow's foot notation (also known as the Information Engineering notation)
  can be used by adding 'notation=crowsfoot' to the 'rake erd' command
  (contributed by Jeremy Holland).
* Filter models by using the only or exclude options (only=ModelOne,ModelTwo
  or exclude=ModelThree,ModelFour) from the command line (contributed by
  Milovan Zogovic).
* Process column types that are unsupported by Rails (contributed by Erik
  Gustavson).
* Ignore custom limit/scale attributes that cannot be converted to an integer
  (reported by Adam St. John).

0.4.5
-----

* Display more helpful error message when the application models could not be
  loaded successfully by the 'rake erd' task (reported by Greg Weber).

0.4.4
-----

* Added the ability to disable HTML markup in node labels (markup=false). This
  causes .dot files to be compatible with OmniGraffle, which otherwise fails
  to import graphs with HTML node labels (issue reported by Lucas Florio,
  implementation based on template by Troy Anderson).
* Prevent models named after Graphviz reserved words (Node, Edge) from causing
  errors in .dot files (reported by gguthrie).
* Improved error messages when Graphviz is throwing errors (reported by
  Michael Irwin).

0.4.3
-----

* Display the scale of decimal attributes when set. A decimal attribute with
  precision 5 and scale 2 is now indicated with (5,2).
* Fixed deprecation warnings for edge Rails (upcoming 3.1).

0.4.1
-----

* Fix processing of associations with class_name set to absolute module paths.
* Adjust model loading process to include models in non-standard paths eagerly.

0.4.0
-----

* Support to optionally display single table inheritance relationships
  (inheritance=true).
* Support to optionally display polymorphic associations (polymorphism=true).
* Adjustments to 'advanced' style so that it matches original Bachman style,
  and therefore now called 'bachman'.
* Ignore models without tables (reported by Mark Chapman).
* Mutual indirect relationships are now combined.
* Changed API for diagram generation.
* Restructured classes and renamed several API properties and methods.
* Added new edge type to describe single table inheritance and polymorphic
  associations: Specialization.
* Added compatibility for Active Record 3.1 (beta), removed dependency on Arel.
* Rubinius compatibility.

0.3.0
-----

* Added the ability to support multiple styles of cardinality notations.
  Currently supported types are 'simple' and 'advanced'.
* Added option to exclude indirect relationships (indirect=false).
* Added option to change or disable the diagram title (title='Custom title').
* Altered the type descriptions of attributes.
* Renamed options for flexibility and clarity.
* Improved internal logic to determine the cardinality of relationships.
* More versatile API that allows you to inspect relationships and their
  cardinalities.
* Changed line widths to 1.0 to avoid invisible node boundaries with older
  versions of Graphviz (reported by Mike McQuinn).
* Bundled examples based on actual applications.

0.2.0
-----

* Added simple way to create your own type of diagrams with a tiny amount of code.
* Improved internal API and documentation.
* Subtle changes in diagram style.
* Fixed error where non-mutual relationships might be inadvertently classified
  as indirect relationships.
* Fixed error where diagrams with a vertical layout might fail to be generated.

0.1.1
-----

* Fixed small errors in Ruby 1.8.7.
* Abort generation of diagrams when there are no models.

0.1.0
-----

* Released on September 20th, 2010.
* First public release.
