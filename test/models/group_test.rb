require 'test_helper'

class GroupTest < ActiveSupport::TestCase
  test 'no variables present' do
    s = ScenarioLoader.new(user: users(:instructor1), name: 'Variables_None', location: :test).fire!
    assert s.valid?
  end

  test 'variables' do
    s = ScenarioLoader.new(user: users(:instructor1), name: 'Variables', location: 'test').fire!
    assert s.valid?

    assert_equal(3, s.variable_templates.count)
    assert_equal(3, s.variables.count)

    assert_equal('foobar', s.variables.first.value)

    g = s.groups.first

    assert_equal(3, g.variable_templates.count)

    p = s.players.first

    assert_equal(3, p.variables.count)
  end
end
