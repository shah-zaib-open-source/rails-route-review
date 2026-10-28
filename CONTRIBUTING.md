# Contributing

Bug reports, documentation improvements, and pull requests are welcome. When
reporting a problem, include a minimal, sanitized route listing, the expected
result, and the Ruby and Rails versions. Do not include private application
routes or credentials.

Run the tests from the project directory:

```sh
ruby -Ilib -Itest -e 'Dir["test/**/*_test.rb"].sort.each { |file| require File.expand_path(file) }'
```

Keep changes focused and add tests for behavior changes. The maintainer reviews
contributions and makes release decisions; project governance can evolve as a
community forms.
