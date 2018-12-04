class Account < ActiveRecord::Base
  has_many :departments

  validates :name, presence: true
end

class Address < ActiveRecord::Base
  belongs_to :addressable, polymorphic: true
end

class Department < ActiveRecord::Base
  belongs_to :account
  has_many :employees
  has_one :address, as: :addressable

  validates :name, :account, presence: true

  attr_accessor :copied_employees_count
end

class Employee < ActiveRecord::Base
  belongs_to :department
  has_many :payrolls

  has_one :address, as: :addressable

  validates :department, presence: true
end

class Payroll < ActiveRecord::Base
  belongs_to :employee

  validates :employee, presence: true
end
