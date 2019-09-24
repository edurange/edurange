require 'test_helper'

class QuestionQueryTest < ActiveSupport::TestCase

  test 'test query language' do

    scenario = scenarios(:ip_test_scenario)

    context = QueryContext.new(
      scenario: scenario,
      player: scenario.players.first
    )

    assert_equal(
      scenario.instances.first.ip_address_private,
      context.evaluate_path('scenario/instances/ip_test_instance/ip_address_private')
    )

    assert_equal(
      '99dffec6',
      context.evaluate_path('scenario/variables/foo'),
    )

    assert_equal(
      scenario.players.first.login,
      context.evaluate_path('player/login')
    )

    assert_equal(
      '76adadf9',
      context.evaluate_path('player/variables/foo')
    )

    assert_raise QueryError do
      context.evaluate_path('player/floom_floggin_flaz')
    end

    assert_raise QueryError do
      context.evaluate_path('player/login/extra')
    end

    assert_raise QueryError do
      context.evaluate_path('blocko_blinko')
    end

    assert_raise QueryError do
      context.evaluate_path('scenario/instances')
    end

    assert_raise QueryError do
      context.evaluate_path('scenario/instances/zzzzzzzz')
    end

    assert_raise QueryError do
      context.evaluate_path('scenario/instances/ip_test_instance')
    end


    assert_raise QueryError do
      context.evaluate_path('scenario/instances/ip_test_instance/floom_floggin_flaz')
    end

    assert_equal(
      '99dffec6',
      context.evaluate('${scenario/variables/foo}')
    )

    assert_equal(
      '99dffec6-76adadf9',
      context.evaluate('${scenario/variables/foo}-${player/variables/foo}')
    )

    assert_equal(
      'plain',
      context.evaluate('plain')
    )

    assert_equal(
      '4.0',
      context.evaluate('4.0')
    )

  end

end
