require 'spec_helper'
require 'seeds'

RSpec.describe Cloned::Strategy do
  class DepartmentStrategy < Cloned::Strategy
    declare :department do
      association :account
      association :address
      association :employees

      nullify :employees_count
      nullify :region

      after do |copy, _target|
        copy.copied_employees_count = copy.employees.size
      end
    end

    declare :employee do
      association :address
    end
  end

  class EmployeeStrategy < Cloned::Strategy
    declare :employee do
      association :address
      association :payrolls, if: ->(payroll) { payroll.total > 1000 }
    end
  end

  let(:account1) { Account.first }
  let(:department_a) { Department.find_by(name: 'Dep A') }
  let(:department_b) { Department.find_by(name: 'Dep B') }
  let(:bob) { Employee.find_by(firstname: 'Bob') }
  let(:account2) { Account.second }

  describe '.cloners_map' do
    let(:department_map) { DepartmentStrategy.cloners_map }
    let(:employee_map) { EmployeeStrategy.cloners_map }

    it 'stores cloners for each model class' do
      expect(department_map.keys).to match_array(%w[Department Employee])
      expect(employee_map.keys).to match_array(%w[Employee])
    end

    it 'defines map for each strategy' do
      expect(department_map).not_to eq(employee_map)
    end
  end

  describe '#make' do
    context 'with conflict in destination' do
      let(:target) { department_a }
      let(:copy) { DepartmentStrategy.make(target: target, destination: account2.departments) }

      it 'resolves destinations' do
        expect { copy }.not_to change { Account.count }
        expect(copy).to be_persisted
        expect(account2.departments).to include(copy)
      end
    end

    context 'with destination' do
      let(:target) { bob }
      let(:destination) { department_b.employees }
      let(:copy) { EmployeeStrategy.make(target: target, destination: destination) }

      it 'builds new record in destination' do
        expect(copy).to be_persisted
        expect(department_b.employees).to include(copy)
        expect(copy.payrolls.size).to be(2)
        expect(copy.address.adds).to eq(bob.address.adds)
      end

      context 'not persisted' do
        let(:destination) { account2.departments.new.employees }

        it 'builds new record in destination' do
          expect(copy).not_to be_persisted
          expect(destination).to include(copy)
          expect(copy.payrolls.size).to be(2)
          expect(copy.address.adds).to eq(bob.address.adds)
        end
      end
    end

    context 'without destination' do
      let(:target) { department_a }
      let(:copy) { DepartmentStrategy.make(target: target) }

      it 'builds new record with expected associations' do
        expect(copy).to be_new_record
        expect(copy.employees_count).to be_nil
        expect(copy.copied_employees_count).to be(1)
        expect(copy.region).to be_nil
        expect(copy.account).to be_new_record
        expect(copy.account.name).to eq(account1.name)
      end

      context 'with has_many association' do
        let(:target) { bob }

        it 'builds new record with expected associations' do
          expect(copy).to be_new_record
          expect(copy.payrolls.size).to be(0)
          expect(copy.address).to be_new_record
          expect(copy.address.adds).to eq(bob.address.adds)
        end
      end
    end
  end
end
