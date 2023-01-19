require 'minitest/autorun'
require 'timeout'

class CustomerSuccessBalancing
  def initialize(customer_success, customers, away_customer_success)
    @customer_success = customer_success
    @customers = customers
    @away_customer_success = away_customer_success
  end

  # Returns the ID of the customer success with most customers
  def execute
    @customer_success = only_active_customers_success(@customer_success, @away_customer_success)
    balance = new_balance
    balance_count = balance.map { |key, value| [key, value.count] }.to_h rescue nil
    last_two_counts = balance_count.max_by(2) { |_, v| v }.to_h rescue nil

    customer_succes_with_most_customers(last_two_counts)
  end

  private

  def customer_succes_with_most_customers(last_two_counts)
    if last_two_counts.nil? || is_a_draw?(last_two_counts)
      0
    else
      max_value = last_two_counts.values.max
      last_two_counts.key(max_value)
    end
  end

  def is_a_draw?(last_two_counts)
    (last_two_counts&.size == 2 && last_two_counts.values.uniq.size == 1)
  end

  def only_active_customers_success(array_customers_success, array_of_indexes)
    array_customers_success.reject { |cs| array_of_indexes.include?(cs[:id]) }
  end

  def new_balance
    new_balance = {}
    @customer_success = @customer_success.sort_by { |cs| cs[:score] }
    @customers.group_by { |customer| @customer_success.find { |cs| cs[:score] >= customer[:score] }[:id] } rescue nil
  end
end

class CustomerSuccessBalancingTests < Minitest::Test
  def test_balance
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 20, 95, 75]),
      build_scores([90, 20, 70, 40, 60, 10]),
      [1, 3]
    )

    balanced_customers = {3=>[{:id=>1, :score=>90}], 2=>[{:id=>2, :score=>20}, {:id=>6, :score=>10}], 4=>[{:id=>3, :score=>70}], 1=>[{:id=>4, :score=>40}, {:id=>5, :score=>60}]}
    assert_equal balanced_customers, balancer.send(:new_balance)
  end

  def test_only_active_customers_success
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 20, 95, 75]),
      build_scores([90, 20, 70, 40, 60, 10]),
      [1, 3]
    )

    @customer_success = balancer.instance_variable_get(:@customer_success)
    @away_customer_success = balancer.instance_variable_get(:@away_customer_success)
    assert_equal [{:id=>2, :score=>20}, {:id=>4, :score=>75}], balancer.send(:only_active_customers_success, @customer_success, @away_customer_success)
  end

  def test_scenario_one
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 20, 95, 75]),
      build_scores([90, 20, 70, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_two
    balancer = CustomerSuccessBalancing.new(
      build_scores([11, 21, 31, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_three
    balancer = CustomerSuccessBalancing.new(
      build_scores(Array(1..999)),
      build_scores(Array.new(10000, 998)),
      [999]
    )
    result = Timeout.timeout(1.0) { balancer.execute }
    assert_equal 998, result
  end

  def test_scenario_four
    balancer = CustomerSuccessBalancing.new(
      build_scores([1, 2, 3, 4, 5, 6]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_five
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 2, 3, 6, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_six
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [1, 3, 2]
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_seven
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [4, 5, 6]
    )
    assert_equal 3, balancer.execute
  end

  private

  def build_scores(scores)
    scores.map.with_index do |score, index|
      { id: index + 1, score: score }
    end
  end
end
