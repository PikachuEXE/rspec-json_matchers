# Story of the project
This file describes the motive of building this project, alternatives and the future.

## Alternative projects that had been used before
The author of this project does his job as a developer mainly on a Ruby on Rails project, which contains endpoints returning responses with JSON data. And he uses RSpec (only) to write tests for those endpoints.

### `json_spec`

#### Usage
At first he was using [`json_spec`](https://github.com/collectiveidea/json_spec), which was good enough for a endpoints with limited number of properties (e.g. an `object` representing a "resource"). The main matcher methods used was:
- `have_json_path` (but actually not used that often)
- `have_json_type`
- `have_json_size`

#### Issues
However, when trying to create examples to verify the actual values of properties, he was unable to find a matcher method for it. Instead he has to use a "helper method" `parse_json` to parse JSON string into a Ruby `Hash` and extract the value from the sometimes deep-nested `Hash`.

Besides, when number of properties increases, it started to become annoying to duplicate & modify the examples for each of properties that requires testing.

### `airborne`

#### Usage
To solve the two issues above, [`airborne`](https://github.com/brooklynDev/airborne) is used. It covers the previous project's features:
- `expect_json_types` => `have_json_type`
- `expect_json_keys`  => `have_json_path`
- `expect_json_sizes` => `have_json_size`

It also solve the two issues of previous project:
- It has an additional method `expect_json`  
  This solves the lack of way of verifying the actual values of properties
- It allows (and maybe only accepts) `Hash` style of expectation  
  And also accepts an optional "path" to avoid writing deep-nested `Hash` in examples
  This solves the need to duplicate examples to verify multiple properties of an `object`.

It has slightly more flexible for type matching, with the following options (copied from its README):
* `:int` or `:integer`
* `:float`
* `:bool` or `:boolean`
* `:string`
* `:date`
* `:object`
* `:null`
* `:array`
* `:array_of_integers` or `:array_of_ints`
* `:array_of_floats`
* `:array_of_strings`
* `:array_of_booleans` or `:array_of_bools`
* `:array_of_objects`
* `:array_of_arrays`
If the properties are optional and may not appear in the response, you can append `_or_null` to the types above.

#### Issues
Sometimes when the symbol was misspelled, a strange error would be raised (seems fixed in recent versions).

Also `:null` was only added recently, which indicates another issue: the lack of possibility to extend the project without raising Pull Requests. This issue is properly not very serious when the project is actively maintained and still easy enough to add changes to it quickly & cleanly (without monkey-patching).


### Other Project
To solve the issues of `airborne`, the author first found other gems, but there are other issues:
#### [`rspec-json_matcher`](https://github.com/r7kamura/rspec-json_matcher)

- It lacks the ability to verify the following things easily
  - number elements of `array`
  - the object type/value with logic "or"

  It is possible with the use of `Proc` since the project use `#===` and `Proc#===` is similar to `Proc#call`) but not quite "easy" (requires much typing)
- The method focusing non built-in "expectation" could lead to silent false positive results, since the definition of `#===` is unclear, it was only used to allow:
  - `Regexp`
  - `Proc`
  - `Class`
  - `Range` (not even mentioned in its README)

There are other classes that define `#===` but with different meanings, remembering/checking the definition of `#===` of classes of custom objects before putting those object as "expectations" (to ensure no false positive result) is not convenient and easy to be forgotten.

#### [`match_json`](https://github.com/WhitePayments/match_json)
- Required to type JSON String as expectations
- Lack of ability to verify
  - the number of elements of `array`
  - the data type

It was discovered during the development of this project.

#### [`json-matchers`](https://github.com/seanpdoyle/json-matchers)
It only supports [JSON Schema](http://json-schema.org/).  
Using JSON Schema to validate JSON lacks the ability to verify the value of property exactly for all data types.  
Also JSON Schema is not a well known standard and lacks stability (the homepage said it's still a draft)

#### [`json-schema`](https://github.com/ruby-json-schema/json-schema)
Same as `json-matchers`


## This Project

### Objectives
- To implement as many features from previous projects as possible
- To solve most issues found in previous projects

### Development Path
- First this project was developed following the pattern of `rspec-json_matcher`, as it has most things required for this project. You can see matcher & comparer classes in this project.
- "Path" support was added to support have the feature provided by `json_spec` & `airborne`
- "Expectation" classes was added to remove the usage of `#===` following the pattern "contract" classes in [`contracts.ruby`](https://github.com/egonSchiele/contracts.ruby) since the author is a user of that project.
- Refactor without the usage of external tool (yet)
- Start using [`appraisal`](https://github.com/thoughtbot/appraisal) to test this gem against all `rspec` versions that should be supported. And that did discover a few errors with `rspec` `3.0`.
- Prepare config file for [Travis](https://travis-ci.org/) (copy from other existing objects)
- Create the first commit (finally)
- Setup related services:
  - [Travis CI](https://travis-ci.org/) to ensure the spec is passed
  - [Gemnasium](https://gemnasium.com/) to ensure the updated dependencies
  - [Code Climate](https://codeclimate.com/) to ensure high code quality
  - [Coveralls](https://coveralls.io/) to ensure high test coverage
  - [Inch CI](https://inch-ci.org/) to ensure inline doc with quality
  - [Gitter](https://gitter.im/) for a free chat room for the project
- Add badges to README
- Refactor according to result from Code Climate & [rubocop](https://github.com/bbatsov/rubocop)
- Improve inline doc according to result from running [inch](https://github.com/rrrene/inch) locally
- Release an "alpha" version and actually it in real project


# Future
In the near future:
- Release a "beta" version for public testing and feedback
- React according to feedback before the official version release, if any
- Add `CONTRIBUTING.md` if appropriate

There are several features that might be considered to be implemented in the future:
- Built-in "expectation" for "date"
- Path matching feature in [`airborne`](https://github.com/brooklynDev/airborne)
- `be_json.with_types` which only accepts classes (only? not sure)
