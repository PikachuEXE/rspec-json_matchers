# RSpec::JsonMatchers

A collection of RSpec matchers for testing JSON data.

[![Gem Version](http://img.shields.io/gem/v/rspec-json_matchers.svg?style=flat-square)](http://badge.fury.io/rb/rspec-json_matchers)
[![License](https://img.shields.io/github/license/PikachuEXE/rspec-json_matchers.svg?style=flat-square)](http://badge.fury.io/rb/rspec-json_matchers)

[![Build Status](http://img.shields.io/travis/PikachuEXE/rspec-json_matchers.svg?style=flat-square)](https://travis-ci.org/PikachuEXE/rspec-json_matchers)
[![Dependency Status](http://img.shields.io/gemnasium/PikachuEXE/rspec-json_matchers.svg?style=flat-square)](https://gemnasium.com/PikachuEXE/rspec-json_matchers)

[![Code Climate](http://img.shields.io/codeclimate/github/PikachuEXE/rspec-json_matchers.svg?style=flat-square)](https://codeclimate.com/github/PikachuEXE/rspec-json_matchers)
[![Coverage Status](http://img.shields.io/coveralls/PikachuEXE/rspec-json_matchers.svg?style=flat-square)](https://coveralls.io/r/PikachuEXE/rspec-json_matchers)
[![Inch CI](https://inch-ci.org/github/PikachuEXE/rspec-json_matchers.svg?branch=master)](https://inch-ci.org/github/PikachuEXE/rspec-json_matchers)

[![Gitter](https://img.shields.io/badge/gitter-join%20chat-1dce73.svg?style=flat-square)](https://gitter.im/PikachuEXE/rspec-json_matchers)

This gem provides a collection of RSpec matchers for testing JSON data.
It aims to make JSON testing flexible & easier, especially for testing multiple properties.
It does not and will not have anything related to JSON Schema.

You can read [the story of this project](https://github.com/PikachuEXE/rspec-json_matchers/blob/master/doc/Story.md) if you have time.

## Installation

Add this line to your application's Gemfile:

```ruby
# `require` can be set to `true` safely without too much side effect
# (except having additional modules & classes defined which could be wasting memory).
# But there is no point requiring it unless in test
# Also maybe add it inside a "group"
gem 'rspec-json_matchers', require: false
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install rspec-json_matchers
```

## Usage

To include the new matchers in your examples,  
add the following code somewhere which will be loaded by `rails_helper`/`spec_helper`:
```ruby
# Remember the `required: false` suggested earlier?
# Now is the time that it is actually "required"
require "rspec-json_matchers"

# This will include matcher methods globally for all spec
# You can choose to include it conditionally, but you should decide yourself
# Or just ignore this comment if you are just trying this out
RSpec.configure do |config|
  config.include RSpec::JsonMatchers::Matchers
end
```

### Matcher `be_json`

This is the starting point of all new matchers.
It can be used alone to ensure that the input can be parsed by `JSON` without error.

```ruby
specify { expect("{}").to be_json } # => pass
specify { expect("[]").to be_json } # => pass
specify { expect("").to be_json }   # => fail
```

### Matcher `be_json.with_content`

This is perhaps the most flexible & powerful matcher in this gem.


#### Content equivalence matching

When passing in "simple data values" (that represents one of JSON data types),  
it matches when they have equivalent values (using `==`).
```ruby
specify { expect("{}").to be_json.with_content(Hash.new) }    # => pass
specify { expect("[]").to be_json.with_content(Array.new) }   # => pass

specify { expect("{}").to be_json.with_content(Hash.new) }    # => fail
specify { expect("[]").to be_json.with_content(Array.new) }   # => fail

# The following line would fail when trying parse the input as JSON
# So you can be sure the input is a valid JSON
specify { expect("").to be_json.with_content(Hash.new) }      # => fail
```

Since it's common to have multiple "properties" in an object,  
the gem allows multiple key as well, instead of having to create multiple examples for all properties you want to test.
```ruby
# Ruby object + `to_json` + Symbol keys is used for easier typing in the following examples,
# but the actual JSON string won't change.

# Matching object with single key with String keys in expected
specify { expect({a: 1}.to_json).to be_json.with_content({"a" => 1}) }    # => pass
# Matching object with single key with Symbol keys in expected
# Symbol keys will be used in the remaining examples, String keys can also be used interchangeably
specify { expect({a: 1}.to_json).to be_json.with_content({a: 1}) }        # => pass

# Obviously
specify { expect({a: 1}.to_json).to be_json.with_content({a: 2}) }        # => fail

# The input can have more keys than expected without failing by default
specify { expect({a: 1, b: 2}.to_json).to be_json.with_content({a: 1}) }  # => pass
# The actual cannot have less keys than expected or will fail the example all the time
specify { expect({a: 1}.to_json).to be_json.with_content({a: 1, b: 2}) }  # => fail
```

It's possible to make examples fail when the object represented by JSON string in `subject`
contains more keys than that in expectation using `with_exact_keys`.

```ruby
# The spec can be set to fail when actual has more keys than expected
specify { expect({a: 1, b: 2}.to_json).to be_json.with_content({a: 1}).with_exact_keys }  # => fail
```

A "path" can also be specified for testing deeply nested data.

```ruby
context "when input is an Hash (in Ruby)" do
  subject do
    {
      a: {
        b: {
          c: 1,
        },
      },
    }.to_json
  end

  it { should be_json.with_content({a: {b: {c: 1}}}) }          # => pass

  it { should be_json.with_content({b: {c: 1}}).at_path("a") }  # => pass
  it { should be_json.with_content({c: 1}).at_path("a.b") }     # => pass
  it { should be_json.with_content(1).at_path("a.b.c") }        # => pass

  # subject without data at path will cause the example to fail
  it { should be_json.with_content(1).at_path("a.b.d") }        # => fail
  it { should be_json.with_content(1).at_path("a.b.c.d") }      # => fail

  # Invalid path will cause the gem to fail, `should` or `should_not`
  # To avoid false positive when used with `should_not`
  it { should be_json.with_content("whatever").at_path(".") }     # => fail
  it { should be_json.with_content("whatever").at_path(".a.") }   # => fail
  it { should be_json.with_content("whatever").at_path("a..c") }  # => fail

  it { should_not be_json.with_content("whatever").at_path(".") }     # => fail
  it { should_not be_json.with_content("whatever").at_path(".a.") }   # => fail
  it { should_not be_json.with_content("whatever").at_path("a..c") }  # => fail

  # Digits can be used as well in path
  specify { expect({'1' => {'2' => 1}}.to_json).to be_json.with_content({'2' => 1}).at_path("1") }
  specify { expect({'1' => {'2' => 1}}.to_json).to be_json.with_content(1).at_path("1.2") }
end

context "when input is an Array (in Ruby)" do
  subject do
    [
      [
        [
          [1],
        ],
      ],
    ].to_json
  end

  it { should be_json.with_content([[[1]]]) }          # => pass

  it { should be_json.with_content([[1]]).at_path("0") }        # => pass
  it { should be_json.with_content([1]).at_path("0.0") }        # => pass
  it { should be_json.with_content(1).at_path("0.0.0") }        # => pass

  # subject without data at path will cause the example to fail
  it { should be_json.with_content(1).at_path("0.0.1") }        # => fail
  it { should be_json.with_content(1).at_path("0.0.0.0") }      # => fail

  # Invalid path will cause the gem to fail, `should` or `should_not`
  # To avoid false positive when used with `should_not`
  it { should be_json.with_content("whatever").at_path(".") }     # => fail
  it { should be_json.with_content("whatever").at_path(".0.") }   # => fail
  it { should be_json.with_content("whatever").at_path("0..0") }  # => fail

  it { should_not be_json.with_content("whatever").at_path(".") }     # => fail
  it { should_not be_json.with_content("whatever").at_path(".0.") }   # => fail
  it { should_not be_json.with_content("whatever").at_path("0..0") }  # => fail

  # The following pass for `should_not`
  # Since the matcher would not know the `actual` should match the path, not the reverse one
  it { should be_json.with_content("whatever").at_path("a") }     # => fail

  it { should_not be_json.with_content("whatever").at_path("a") } # => pass
end
```


#### Special content matching

Besides objects representing JSON data types, there are other objects that can be passed in as special expectation.

```ruby
# Pass when subject is a String & matches the Regex
context "when expected is a Regexp" do
  specify { expect({url: "https://domain.com"}.to_json).to be_json.with_content(url: %r|^https://|) } # => pass
  specify { expect({url: "http://domain.com"}.to_json).to be_json.with_content(url: %r|^https://|) }  # => fail
  specify { expect({url: 1}.to_json).to be_json.with_content(url: %r|^https://|) }                    # => fail
end

# Pass when subject is "covered" by the Range
context "when expected is a Range" do
  specify { expect({age: 1}.to_json).to be_json.with_content(age: (1...10)) }   # => pass
  specify { expect({age: 10}.to_json).to be_json.with_content(age: (1...10)) }  # => fail
  specify { expect({age: '1'}.to_json).to be_json.with_content(age: (1...10)) } # => fail

  # Supports whatever Range supports, using #cover?
  specify { expect({age: '1'}.to_json).to be_json.with_content(age: ('1'...'10')) } # => fail
end

# Pass when callable returns true
context "when expected is a callable" do
  class ExampleCallable
    def self.call(v)
      new.call(v)
    end

    def call(v)
      true
    end
  end

  specify { expect({a: "whatever"}.to_json).to be_json.with_content(a: proc { true }) }       # => pass
  specify { expect({a: "whatever"}.to_json).to be_json.with_content(a: lambda {|_| true }) }  # => pass
  specify { expect({a: "whatever"}.to_json).to be_json.with_content(a: -> (_) { true }) }     # => pass

  specify { expect({a: "whatever"}.to_json).to be_json.with_content(a: ExampleCallable) }     # => pass
  specify { expect({a: "whatever"}.to_json).to be_json.with_content(a: ExampleCallable.new) } # => pass

  specify { expect({a: "whatever"}.to_json).to be_json.with_content(a: -> { true }) }         # => error
  specify { expect({a: "whatever"}.to_json).to be_json.with_content(a: -> (a, b) { true }) }  # => error
end

# Pass when subject's class (in Ruby form) inherits / same as expected
context "when expected is a callable" do
  specify { expect({a: 1}.to_json).to be_json.with_content(a: String) }   # => fail
  specify { expect({a: 1}.to_json).to be_json.with_content(a: Integer) }  # => pass
  specify { expect({a: 1}.to_json).to be_json.with_content(a: Numeric) }  # => pass
end
```


#### Custom/Complex Expectations

Passing in a `Range` like (e.g. `('a'..'c')`) is telling the example to pass
only when the actual value equals to any of the values represented by the Range `'a' / 'b' / 'c'`.  

But there is no way to specify other "OR" expectations easily (e.g. `'a' / 'c'`)
since `Array` is already used for data structure expectation.  
So the gem also provides a list of classes to represent these kinds of custom expectations to be used.  

##### Setup

First, it requires some setup.  
You can put the following code in any sensible place like a specific spec file or `rails_helper`.
```ruby
module Expectations
  include RSpec::JsonMatchers::Expectations::Mixins::BuiltIn
end
```

Alternatively, you can use `let` to define a module without name,
to avoid creating top-namespaced constant  
```ruby
let(:expectations) do
  Module.new do
    include RSpec::JsonMatchers::Expectations::Mixins::BuiltIn
  end
end
```

If you really want to save typing `expectations::` and are not afraid of constant name conflicts,  
You can add the following somewhere.
Note that you must use both `before(:each)` & `stub_const` to make this work.
Please tell us if you have other methods to achieve the same effect.
```ruby
before(:each) do
  RSpec::JsonMatchers::Expectations::Mixins::BuiltIn.constants.each do |expectation_klass_name|
    stub_const(
      expectation_klass_name.to_s,
      RSpec::JsonMatchers::Expectations::Mixins::BuiltIn.const_get(expectation_klass_name),
    )
  end
end
```

##### Usage

Now let's take a look at the actual expectation classes this gem provides:
```ruby
# `Anything` is an expectation that always passes
# It has the same effect as passing `Object` in
# Since every Ruby form of JSON data type is an `Object`
# But this would be more verbose & clear
specify { expect({a: "a"  }.to_json).to be_json.with_content(a: expectations::Anything) }  # => pass
specify { expect({a: 1    }.to_json).to be_json.with_content(a: expectations::Anything) }  # => pass
specify { expect({a: 1.1  }.to_json).to be_json.with_content(a: expectations::Anything) }  # => pass
specify { expect({a: {}   }.to_json).to be_json.with_content(a: expectations::Anything) }  # => pass
specify { expect({a: []   }.to_json).to be_json.with_content(a: expectations::Anything) }  # => pass
specify { expect({a: true }.to_json).to be_json.with_content(a: expectations::Anything) }  # => pass
specify { expect({a: false}.to_json).to be_json.with_content(a: expectations::Anything) }  # => pass
specify { expect({a: nil  }.to_json).to be_json.with_content(a: expectations::Anything) }  # => pass


# `PositiveNumber` is an expectation that passes when subject is a `Numeric` and larger than 0
specify { expect({a: 1    }.to_json).to be_json.with_content(a: expectations::PositiveNumber) } # => pass
specify { expect({a: 1.1  }.to_json).to be_json.with_content(a: expectations::PositiveNumber) } # => pass
specify { expect({a: 0    }.to_json).to be_json.with_content(a: expectations::PositiveNumber) } # => fail
specify { expect({a: 0.0  }.to_json).to be_json.with_content(a: expectations::PositiveNumber) } # => fail
specify { expect({a: -1   }.to_json).to be_json.with_content(a: expectations::PositiveNumber) } # => fail
specify { expect({a: -1.1 }.to_json).to be_json.with_content(a: expectations::PositiveNumber) } # => fail


# `NegativeNumber` is an expectation that passes when subject is a `Numeric` and less than 0
specify { expect({a: 1    }.to_json).to be_json.with_content(a: expectations::NegativeNumber) } # => fail
specify { expect({a: 1.1  }.to_json).to be_json.with_content(a: expectations::NegativeNumber) } # => fail
specify { expect({a: 0    }.to_json).to be_json.with_content(a: expectations::NegativeNumber) } # => fail
specify { expect({a: 0.0  }.to_json).to be_json.with_content(a: expectations::NegativeNumber) } # => fail
specify { expect({a: -1   }.to_json).to be_json.with_content(a: expectations::NegativeNumber) } # => pass
specify { expect({a: -1.1 }.to_json).to be_json.with_content(a: expectations::NegativeNumber) } # => pass


# `BooleanValue` is an expectation that passes when subject is a `TrueClass` or `FalseClass`
specify { expect({a: "a"  }.to_json).to be_json.with_content(a: expectations::BooleanValue) }  # => fail
specify { expect({a: 1    }.to_json).to be_json.with_content(a: expectations::BooleanValue) }  # => fail
specify { expect({a: 1.1  }.to_json).to be_json.with_content(a: expectations::BooleanValue) }  # => fail
specify { expect({a: {}   }.to_json).to be_json.with_content(a: expectations::BooleanValue) }  # => fail
specify { expect({a: []   }.to_json).to be_json.with_content(a: expectations::BooleanValue) }  # => fail
specify { expect({a: true }.to_json).to be_json.with_content(a: expectations::BooleanValue) }  # => pass
specify { expect({a: false}.to_json).to be_json.with_content(a: expectations::BooleanValue) }  # => pass
specify { expect({a: nil  }.to_json).to be_json.with_content(a: expectations::BooleanValue) }  # => fail


# `ArrayOf` is an expectation that passes when subject is an `Array` and
# **ALL** elements satisfy the expectation passed in
specify { expect({a: "a"  }.to_json).to be_json.with_content(a: expectations::ArrayOf[expectations::Anything]) }  # => fail
specify { expect({a: 1    }.to_json).to be_json.with_content(a: expectations::ArrayOf[expectations::Anything]) }  # => fail
specify { expect({a: 1.1  }.to_json).to be_json.with_content(a: expectations::ArrayOf[expectations::Anything]) }  # => fail
specify { expect({a: {}   }.to_json).to be_json.with_content(a: expectations::ArrayOf[expectations::Anything]) }  # => fail
specify { expect({a: []   }.to_json).to be_json.with_content(a: expectations::ArrayOf[expectations::Anything]) }  # => pass
specify { expect({a: true }.to_json).to be_json.with_content(a: expectations::ArrayOf[expectations::Anything]) }  # => fail
specify { expect({a: false}.to_json).to be_json.with_content(a: expectations::ArrayOf[expectations::Anything]) }  # => fail
specify { expect({a: nil  }.to_json).to be_json.with_content(a: expectations::ArrayOf[expectations::Anything]) }  # => fail

# As you see it allows empty array by default
# Since {Enumerable#all?} returns `true` when collection is empty
# You can make it fail using optional argument in {#allow_empty} or {#disallow_empty}
# Notice that {#disallow_empty} has no optional argument to avoid reading as double negative
specify do
  expect({a: []}.to_json).to be_json.
    with_content(a: expectations::ArrayOf[expectations::Anything].allow_empty)
end # => pass
specify do
  expect({a: []}.to_json).to be_json.
    with_content(a: expectations::ArrayOf[expectations::Anything].allow_empty(true))
end # => pass
specify do
  expect({a: []}.to_json).to be_json.
    with_content(a: expectations::ArrayOf[expectations::Anything].allow_empty(false))
end # => fail
specify do
  expect({a: []}.to_json).to be_json.
    with_content(a: expectations::ArrayOf[expectations::Anything].disallow_empty)
end # => fail


# `ArrayWithSize` is an expectation that passes when subject is an `Array` and
# The size satisfies the `Fixnum`, `Bignum` or `Range` passed in
# Passing "expectation" with unexpected type would simply fail the example
# This also means using `should_not` with unexpected type of "expectation" always pass
specify do
  expect({a: [1]}.to_json).to be_json.
    with_content(a: expectations::ArrayWithSize[1])
end # => pass
specify do
  expect({a: [1]}.to_json).to be_json.
    with_content(a: expectations::ArrayWithSize[0..2])
end # => pass
specify do
  expect({a: [1]}.to_json).to be_json.
    with_content(a: expectations::ArrayWithSize[1.1])
end # => error

# You can pass more than 1 objects in as expectation
# It will pass when ANY of them "expects" the size
specify do
  expect({a: [1]}.to_json).to be_json.
    with_content(a: expectations::ArrayWithSize[0, 1, 3])
end # => pass


# `NullableOf` is an expectation that works like `AnyOf`
# Except it always passes when the subject is `nil`
specify do
  expect({a: 1}.to_json).to be_json.
    with_content(a: expectations::NullableOf[1])
end # => pass
specify do
  expect({a: 1}.to_json).to be_json.
    with_content(a: expectations::NullableOf[0, 1, 2])
end # => pass
specify do
  expect({a: 1}.to_json).to be_json.
    with_content(a: expectations::NullableOf[false, expectations::Anything, false])
end # => pass
specify do
  expect({a: 1}.to_json).to be_json.
    with_content(a: expectations::NullableOf[false, false, false])
end # => fail
specify do
  expect({a: nil}.to_json).to be_json.
    with_content(a: expectations::NullableOf[false, false, false])
end # => fail


# `AnyOf` is an expectation that passes when **any** of "expectations" passed in
# "expects" the subject
# It will convert non `Expectation` objects into `Expectation` objects,
# just like using `with_content` alone
specify do
  expect({a: 1}.to_json).to be_json.
    with_content(a: expectations::AnyOf[1])
end # => pass
specify do
  expect({a: 1}.to_json).to be_json.
    with_content(a: expectations::AnyOf[0, 1, 2])
end # => pass
specify do
  expect({a: 1}.to_json).to be_json.
    with_content(a: expectations::AnyOf[false, expectations::Anything, false])
end # => pass
specify do
  expect({a: 1}.to_json).to be_json.
    with_content(a: expectations::AnyOf[false, false, false])
end # => fail


# `AllOf` is an expectation that passes when **all** of "expectations" passed in
# "expects" the subject
# It will convert non `Expectation` objects into `Expectation` objects,
# just like using `with_content` alone
specify do
  expect({a: 1}.to_json).to be_json.
    with_content(a: expectations::AllOf[1])
end # => pass
specify do
  expect({a: 1}.to_json).to be_json.
    with_content(a: expectations::AllOf[1, (1..2), expectations::PositiveNumber])
end # => pass
specify do
  expect({a: 1}.to_json).to be_json.
    with_content(a: expectations::AllOf[0, 1, 2])
end # => fail
specify do
  expect({a: 1}.to_json).to be_json.
    with_content(a: expectations::AllOf[false, expectations::Anything, false])
end # => fail
specify do
  expect({a: 1}.to_json).to be_json.
    with_content(a: expectations::AllOf[false, false, false])
end # => fail
```

#### Custom/Complex Expectations NOT included on purpose

##### Date
In [`airborne`](https://github.com/brooklynDev/airborne) you can validate the value as a "date" (and "time").  
However "date/time" is not part of the JSON specification.  
Some people use a string with a format specified in ISO to represent a time, but a [Unix time](https://en.wikipedia.org/wiki/Unix_time).  
So this gem does not try to be "smart" to have a "generic" expectation for "date/time".  
New expectations might be added in the future, to the core gem or a new extension gem, for common formats of "date" values.  
There is no clear schedule for the addition yet, so you should try to add your own expectation class to suit your application.  


### Matcher `be_json.with_sizes`

Used to have in earlier alpha versions.
Indended to ease the migration from other gems but 
it also makes the gem more difficult to maintain.
Removed in later alpha version(s).

Just use `ArrayWithSize`


```ruby
specify do
  expect({a: [1]}.to_json).to be_json.
    with_sizes(a: ArrayWithSize[1])
end # => pass
specify do
  expect({a: [1]}.to_json).to be_json.
    with_sizes(a: ArrayWithSize[(0..2)])
end # => pass
specify do
  expect({a: [1]}.to_json).to be_json.
    with_sizes(a: ArrayWithSize[1.1])
end # => error
```


### Matcher `be_json.with_types`

Unlike gems such as
[`airborne`](https://github.com/brooklynDev/airborne) or
[`json_spec`](https://github.com/collectiveidea/json_spec),
there is no such matcher.  
Just use `be_json.with_content` with classes.  


## Pitfalls

### Error message colorized output in RubyMine

Add something like
`-rawesome_print -e "AwesomePrint.defaults={plain: true}"` to `Ruby arguments`
for `Run/Debug Configurations => Defaults => RSpec`  
That way you could keep the color when running `rspec` from console


## Contributing

1. Fork it ( https://github.com/PikachuEXE/rspec-json_matchers/fork )
2. Create your branch (Preferred to be prefixed with `feature`/`fix`/other sensible prefixes)
3. Commit your changes (No version related changes will be accepted)
4. Push to the branch on your forked repo
5. Create a new Pull Request
