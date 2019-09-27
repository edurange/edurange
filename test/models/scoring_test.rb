require 'test_helper'

class ScoringTest < ActiveSupport::TestCase

	test 'text presence' do
		s = scenarios(:two)
		q = Question.new(order: 1, type_of: 'String', values: [{value: "foo", points: 1}], scenario_id: s.id)
		q.save
		assert_not q.valid?
		assert_equal [:text], q.errors.keys
	end

	test 'type presence' do
		s = scenarios(:two)
		q = Question.new(text: "foo", order: 1, values: [{value: "foo", points: 1}], scenario_id: s.id)
		assert_not q.valid?
		assert_equal [:type_of], q.errors.keys
	end

	test 'value presence' do
		s = scenarios(:two)

		# values must be present
		q = Question.new(text: "foo", order: 1, type_of: "String", scenario_id: s.id)
		q.save
		assert_not q.valid?
		assert_equal [:values], q.errors.keys

		# values should not be blank
		q.values = []
		q.save
		assert_not q.valid?
		assert_equal [:values], q.errors.keys

		# values should be a list of hashses
		q.values = ["foo"]
		q.save
		assert_not q.valid?
		assert_equal [:values], q.errors.keys

		# hashes should not be empty
		q.values = [{}]
		q.save
		assert_not q.valid?
		assert_equal [:values], q.errors.keys

		# hashes shoudl contain the fields 'value', 'special' and 'points'
		q.values = [{value: 1}]
		q.save
		assert_not q.valid?
		assert_equal [:values], q.errors.keys

		# hashses should not contain more than 3 fields
		q.values = [{value: "foo", special: 'special', points: 1, extra: 2}]
		q.save
		assert_not q.valid?
		assert_equal [:values], q.errors.keys

		# hashses should not be empty
		q.values = [{value: "foo", points: 1}, {}]
		q.save
		assert_not q.valid?
		assert_equal [:values], q.errors.keys

		# must all be hashes
		q.values = [{value: "foo", points: 1}, {value: "bar", points: 1}, "foo"]
		q.save
		assert_not q.valid?
		assert_equal [:values], q.errors.keys

		# no duplicated values in hashes
		q.values = [{value: " foo", points: 1}, {value: "foo ", points: 1}]
		q.save
		assert_not q.valid?
		assert_equal [:values], q.errors.keys

		# this is correct
		q.values = [{value: "foo", points: 1}]
		q.save
		assert q.valid?
		assert_equal [], q.errors.keys

		# this one is also correct
		q.values = [{value: "foo", points: 1}, {value: "bar", points: 1}]
		q.save
		assert q.valid?
		assert_equal [], q.errors.keys

		# no equivalent values
		q.type_of = "Number"
		q.options = ["accept-integer", "accept-decimal"]
		q.values = [{value: "1", points: 1}, {value: "1.0", points: 1}]
		q.save
		assert_not q.valid?
		assert_equal [:values], q.errors.keys

		q.options = ["accept-integer", "accept-decimal", "accept-hex"]
		q.values = [{value: "0x01", points: 1}, {value: "1.0", points: 1}]
		q.save
		assert_not q.valid?
		assert_equal [:values], q.errors.keys

		q.options = ["accept-integer", "accept-decimal", "accept-hex"]
		q.values = [{value: "0x01", points: 1}, {value: "1", points: 1}]
		q.save
		assert_not q.valid?
		assert_equal [:values], q.errors.keys
	end

	test 'options' do
		s = scenarios(:two)

		# options default to empty list
		q = Question.new(text: "foo", order: 1, type_of: "String", values: [{value: "1", points: 1}], scenario_id: s.id)
		q.save
		assert q.valid?
		assert_equal q.options, []

		# possible types "String", "Number", "Essay", "Event"
		q.type_of = "None"
		q.save
		assert_not q.valid?
		assert_equal [:type_of], q.errors.keys

		q.type_of = "String"
		q.save
		assert q.valid?

		# not a valid option for string
		q.options = ["accept-integer"]
		q.save
		assert_not q.valid?
		assert_equal [:options], q.errors.keys

		q.options = ["ignore-case"]
		q.save
		assert q.valid?

		# number type must contain at least one option, values will also fail because there is no option for type accepted
		q.type_of = "Number"
		q.options = []
		q.save
		assert_not q.valid?
		assert_equal [:options, :values], q.errors.keys

		q.options = ["none"]
		q.save
		assert_not q.valid?
		assert_equal [:options, :values], q.errors.keys

		q.options = ["accept-integer", "foo"]
		q.save
		assert_not q.valid?
		assert_equal [:options], q.errors.keys

		q.options = ["accept-integer"]
		q.save
		assert q.valid?

		# values must be integer because that is what is accepted
		q.values = [{value: "foo", points: 1}]
		q.save
		assert_not q.valid?
		assert_equal [:values], q.errors.keys

		q.values = [{value: "10.0", points: 1}]
		q.save
		assert_not q.valid?
		assert_equal [:values], q.errors.keys

		q.values = [{value: "10.0a", points: 1}]
		q.save
		assert_not q.valid?
		assert_equal [:values], q.errors.keys

		q.values = [{value: "0xff", points: 1}]
		q.save
		assert_not q.valid?
		assert_equal [:values], q.errors.keys

		q.values = [{value: " 10 ", points: 1}]
		q.save
		assert q.valid?

		q.values = [{value: " -10", points: 1}]
		q.save
		assert q.valid?

		q.values = [{value: "+10 ", points: 1}]
		q.save
		assert q.valid?

		# try accept decimal
		q.options = ["accept-decimal"]
		q.values = [{value: "+10.9999 ", points: 1}]
		q.save
		assert q.valid?

		q.values = [{value: "+10.4 ", points: 1}]
		q.save
		assert q.valid?

		q.values = [{value: " +10.0 ", points: 1}]
		q.save
		assert q.valid?

		q.values = [{value: "-.0 ", points: 1}]
		q.save
		assert q.valid?

		q.values = [{value: "+111.0 ", points: 1}]
		q.save
		assert q.valid?

		q.values = [{value: "+a111.0 ", points: 1}]
		q.save
		assert_not q.valid?
		assert_equal [:values], q.errors.keys

		q.values = [{value: " 0xff ", points: 1}]
		q.save
		assert_not q.valid?
		assert_equal [:values], q.errors.keys

		# try accept hex
		q.options = ["accept-hex"]
		q.values = [{value: " 0x0 ", points: 1}]
		q.save
		assert q.valid?

		q.values = [{value: " 0xcca1112bef ", points: 1}]
		q.save
		assert q.valid?

		q.values = [{value: " 00x0", points: 1}]
		q.save
		assert_not q.valid?
		assert_equal [:values], q.errors.keys

		q.values = [{value: " -10.0", points: 1}]
		q.save
		assert_not q.valid?
		assert_equal [:values], q.errors.keys

		q.values = [{value: " 10 ", points: 1}]
		q.save
		assert_not q.valid?
		assert_equal [:values], q.errors.keys

		q.values = [{value: " asf ", points: 1}]
		q.save
		assert_not q.valid?
		assert_equal [:values], q.errors.keys

		# do essay
		q.type_of = "Essay"
		q.options = []
		q.save
		assert q.valid?

		q.options = ["wrong"]
		q.save
		assert_not q.valid?
		assert_equal [:options], q.errors.keys

		q.options = ["larger-text-field"]
		q.save
		assert q.valid?

	end

	test 'text uniqueness' do
		s = scenarios(:two)

		q = Question.new(text: "foo", order: 1, type_of: "String", values: [{value: "1", points: 1}], scenario_id: s.id)
		q2 = Question.new(text: "foo", order: 1, type_of: "String", values: [{value: "1", points: 1}], scenario_id: s.id)
		q.save
		q2.save

		assert_not q2.valid?

		q2.text = "bar"
		q2.save

		assert q2.valid?
	end

	test 'order' do
		s = scenarios(:two)

		q1 = Question.new(text: "foo", type_of: "String", values: [{value: "1", points: 1}], scenario_id: s.id)
		q2 = Question.new(text: "bar", type_of: "String", values: [{value: "1", points: 1}], scenario_id: s.id)
		q3 = Question.new(text: "baz", type_of: "String", values: [{value: "1", points: 1}], scenario_id: s.id)
		q1.save
		q2.save
		q3.save

		assert q1.valid?
		assert q2.valid?
		assert q3.valid?

		assert q1.order == 1
		assert q2.order == 2
		assert q3.order == 3

		q1 = q1.move_down
		assert q1.order == 1
		assert q2.order == 2
		assert q3.order == 3

		# set q2 here or reload because move_up has side effects on the database
		q2 = q1.move_up
		assert q1.order == 2
		assert q2.order == 1
		assert q3.order == 3

		q3 = q1.move_up
		assert q1.order == 3
		assert q2.order == 1
		assert q3.order == 2

		q1 = q1.move_up
		assert q1.order == 3
		assert q2.order == 1
		assert q3.order == 2

		q3 = q1.move_down
		assert q1.order == 2
		assert q2.order == 1
		assert q3.order == 3

		q2 = q1.move_down
		assert q1.order == 1
		assert q2.order == 2
		assert q3.order == 3
	end

	test 'answer string' do
		s = scenarios(:two)
		st = users(:student1)
		q1 = Question.new(text: "foo", type_of: "String", values: [{value: "foo", points: 1}], scenario_id: s.id)
		q1.save
		assert q1.valid?

		a = q1.answer_string("", st.id)
		assert_equal [:text], a.errors.keys

		a = q1.answer_string("", st.id)
		assert_equal [:text], a.errors.keys

		a = q1.answer_string("    ", st.id)
		assert_equal [:text], a.errors.keys

		a = q1.answer_string("foo", st.id)
		assert_equal [], a.errors.keys

		b = q1.answer_string("foo", st.id)
		assert_equal [:duplicate], b.errors.keys

		b = q1.answer_string(" foo ", st.id)
		assert_equal [:duplicate], b.errors.keys

		b = q1.answer_string(" Foo ", st.id)
		assert_equal [], b.errors.keys

		q1.reload
		q1.options = ["ignore-case"]
		q1.save
		assert_equal [], q1.errors.keys, "#{q1.errors.messages}"

		b = q1.answer_string(" Foo ", st.id)
		assert_equal [:duplicate], b.errors.keys

		c = q1.answer_string(" FooBar ", st.id)
		assert_equal [], c.errors.keys
	end

	test 'answer number' do
		s = scenarios(:two)
		st = users(:student1)
		q1 = Question.new(text: "foo", type_of: "Number", options: ["accept-integer"], values: [{value: "1", points: 1}], scenario_id: s.id)
		q1.save
		assert q1.valid?
		assert_equal [], q1.errors.keys

		# fail if not number type
		q1.type_of = "String"
		q1.save
		a = q1.answer_number("1", st.id)
		assert_equal [:type_of], a.errors.keys

		# fail because answer is decimal not integer
		q1.type_of = "Number"
		q1.save
		a = q1.answer_number("1.0", st.id)
		assert_equal [:options], a.errors.keys

		# fail because answer is hex not integer
		a = q1.answer_number("0xff", st.id)
		assert_equal [:options], a.errors.keys

		# fail because answer is not anything
		a = q1.answer_number("1000000z0000", st.id)
		assert_equal [:options], a.errors.keys

		# yes integer but not correct
		a = q1.answer_number("100", st.id)
		assert_equal [], a.errors.keys
		assert_not a.correct

		# yes integer but not correct
		a = q1.answer_number("-1", st.id)
		assert_equal [], a.errors.keys
		assert_not a.correct

		# correct
		a = q1.answer_number(" 1 ", st.id)
		assert_equal [], a.errors.keys
		assert a.correct

		# correct
		a = q1.answer_number(" +1 ", st.id)
		assert_equal [:duplicate], a.errors.keys

		q1.answers.destroy_all
		q1.options = ["accept-decimal"]
		q1.values = [{value: "2.0", points: 1}]
		q1.save
		assert q1.valid?

		# dont accept integer
		a = q1.answer_number(" +2 ", st.id)
		assert_equal [:options], a.errors.keys

		# dont accept hex
		a = q1.answer_number(" 0x02 ", st.id)
		assert_equal [:options], a.errors.keys

		# correct
		a = q1.answer_number(" +2.0 ", st.id)
		assert_equal [], a.errors.keys
		assert a.correct

		# no duplicates
		a = q1.answer_number(" 2.000 ", st.id)
		assert_equal [:duplicate], a.errors.keys

		q1.reload
		assert q1.answers.size == 1

	end

	test 'answer essay' do
		s = scenarios(:two)
		st = users(:student1)
		q1 = Question.new(text: "foo", type_of: "Number", options: ["accept-integer"], values: [{value: "1", points: 1}], scenario_id: s.id)
		q1.save
		assert q1.valid?, q1.errors.messages
		assert_equal [], q1.errors.keys

		# question is not Essay type
		a = q1.answer_essay("foo", st.id)
		assert_equal [:type_of], a.errors.keys

		q1.type_of = "Essay"
		q1.options = []
		q1.save
		assert q1.valid?

		# no blank answers
		a = q1.answer_essay("", st.id) #not getting linked properly
		a.question = q1
		assert_equal [:text_essay], a.errors.keys

		a = q1.answer_essay("      ", st.id)
		assert_equal [:text_essay], a.errors.keys

		# valid answer should save without errors
		a = q1.answer_essay("foo", st.id)
		assert_equal [], a.errors.keys
		assert a.valid?
	end

	test 'special' do
		skip("we have removed the ip_address_dynamic feature for now")
		scenario = scenarios(:ip_test_scenario)
		instance = scenario.instances.select { |i| i.name == 'ip_test_instance' }.first

		# test special string
		q1 = scenario.questions.new(
			text: "foo",
			type_of: "String",
			options: [],
			values: [{value: "$ip_test_instance$", points: 1}]
		)
		q1.save
		assert q1.valid?, q1.errors.messages
		assert_equal [], q1.errors.keys
		assert_equal(
			q1.values.first[:value],
			instance.ip_address,
			"#{q1.values.first[:value]} #{instance.ip_address}"
		)
		assert_equal "10.0.0.4", q1.values.first[:value]
		assert_equal "$ip_test_instance$", q1.values.first[:special]

		# test special string with added chars
		q1 = scenario.questions.new(
			text: "foo2",
			type_of: "String",
			options: [],
			values: [{value: "before$ip_test_instance$after", points: 1}]
		)
		q1.save
		assert q1.valid?, q1.errors.messages
		assert_equal [], q1.errors.keys
		assert_equal(
			q1.values.first[:value],
			'before' + instance.ip_address + 'after',
			"#{q1.values.first[:value]} #{instance.ip_address}"
		)
		assert_equal "before10.0.0.4after", q1.values.first[:value]
		assert_equal "before$ip_test_instance$after", q1.values.first[:special]

		# test failed special string
		q1 = scenario.questions.new(
			text: "foo3",
			type_of: "String",
			options: [],
			values: [{value: "$none$p22", points: 1}]
		)
		q1.save
		assert q1.valid?, q1.errors.messages
		assert_equal [], q1.errors.keys
		assert_equal(
			q1.values.first[:value],
			"$none$p22",
			"#{q1.values.first[:value]} #{instance.ip_address}"
		)
		assert_not q1.values.first[:special]
		assert_equal "$none$p22", q1.values.first[:value]
	end

end
