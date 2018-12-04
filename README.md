# Cloned

Simple gem for copying trees of ActiveRecord models.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cloned'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cloned

## Usage

First you need to define clonning stategy:

```ruby
class CompanyCopyStrategy < Cloned::Strategy
  declare :company do
    before do |copied_company, _target_company|
      copied_company.copied_at = Time.zone.now
    end

    after do |copied_company, _target_company|
      copied_company.departments_count = copied_company.departments.size
    end

    nullify :created_at, :updated_at

    association(:departments)
  end

  declare :department do
    association :employees, if: ->(employee) { employee.salary > 2000 }
  end

  declare :employee do
    nullify :last_sickleave, :vacation_at
  end
end
```
Then you able to build or create clones:

```ruby
CompanyCopyStrategy.make(target: Company.first, destination: Account.last.companies)
```
or
```ruby
CompanyCopyStrategy.make(target: Company.first)
```
Cloning destination can be has_many association or nil.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fs/cloned.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
