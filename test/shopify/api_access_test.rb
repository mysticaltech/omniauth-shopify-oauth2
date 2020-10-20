require 'omniauth-shopify-oauth2'

class ScopesTest < Minitest::Test
  def test_write_is_the_same_access_as_read_write_on_the_same_resource
    full_scopes = OmniAuth::Shopify::ApiAccess.new(%w(read_orders write_orders))
    expected_scopes = OmniAuth::Shopify::ApiAccess.new(%w(write_orders))
    assert_equal expected_scopes, full_scopes
  end

  def test_write_is_the_same_access_as_read_write_on_the_same_unauthenticated_resource
    full_scopes = OmniAuth::Shopify::ApiAccess.new(%w(unauthenticated_read_orders unauthenticated_write_orders))
    expected_scopes = OmniAuth::Shopify::ApiAccess.new(%w(unauthenticated_write_orders))
    assert_equal expected_scopes, full_scopes
  end

  def test_read_is_not_the_same_as_read_write_on_the_same_resource
    scopes = OmniAuth::Shopify::ApiAccess.new(%w(read_orders))
    non_equivalent_scopes = OmniAuth::Shopify::ApiAccess.new(%w(write_orders read_orders))
    refute_equal non_equivalent_scopes, scopes
  end

  def test_two_different_resources_are_not_equal
    resource_a_scopes = OmniAuth::Shopify::ApiAccess.new(%w(read_orders))
    resource_b_scopes = OmniAuth::Shopify::ApiAccess.new(%w(read_products))
    refute_equal resource_a_scopes, resource_b_scopes
  end

  def test_two_identical_scopes_are_equal
    scopes = OmniAuth::Shopify::ApiAccess.new(%w(read_orders))
    equivalent_scopes = OmniAuth::Shopify::ApiAccess.new(%w(read_orders))
    assert_equal equivalent_scopes, scopes
  end

  def test_unauthenticated_is_not_implied_by_authenticated_access
    unauthenticated_scopes = OmniAuth::Shopify::ApiAccess.new(%w(unauthenticated_read_orders))
    authenticated_read_scopes = OmniAuth::Shopify::ApiAccess.new(%w(read_orders))
    authenticated_write_scopes = OmniAuth::Shopify::ApiAccess.new(%w(write_orders))
    refute_equal unauthenticated_scopes, authenticated_read_scopes
    refute_equal unauthenticated_scopes, authenticated_write_scopes
  end

  def test_scopes_includes_is_truthy_for_same_scopes
    scopes = OmniAuth::Shopify::ApiAccess.new(%w(read_orders))
    other_scopes = OmniAuth::Shopify::ApiAccess.new(%w(read_orders))
    assert scopes.covers?(other_scopes)
  end

  def test_covers_is_falsy_for_different_scopes
    scopes = OmniAuth::Shopify::ApiAccess.new(%w(read_orders))
    other_scopes = OmniAuth::Shopify::ApiAccess.new(%w(read_products))
    refute scopes.covers?(other_scopes)
  end

  def test_covers_is_truthy_for_read_when_the_set_has_read_write
    scopes = OmniAuth::Shopify::ApiAccess.new(%w(write_products))
    other_scopes = OmniAuth::Shopify::ApiAccess.new(%w(read_products))
    assert scopes.covers?(other_scopes)
  end

  def test_covers_is_truthy_for_read_when_the_set_has_read_write_for_that_resource_and_others
    scopes = OmniAuth::Shopify::ApiAccess.new(%w(write_products, write_orders))
    other_scopes = OmniAuth::Shopify::ApiAccess.new(%w(read_orders))
    assert scopes.covers?(other_scopes)
  end

  def test_covers_is_truthy_for_write_when_the_set_has_read_write_for_that_resource_and_others
    scopes = OmniAuth::Shopify::ApiAccess.new(%w(write_products, write_orders))
    other_scopes = OmniAuth::Shopify::ApiAccess.new(%w(write_orders))
    assert scopes.covers?(other_scopes)
  end

  def test_covers_is_truthy_for_subset_of_scopes
    scopes = OmniAuth::Shopify::ApiAccess.new(%w(write_products write_orders write_customers))
    other_scopes = OmniAuth::Shopify::ApiAccess.new(%w(write_orders read_products))
    assert scopes.covers?(other_scopes)
  end

  def test_covers_is_falsy_for_sets_of_scopes_that_have_no_common_elements
    scopes = OmniAuth::Shopify::ApiAccess.new(%w(write_products write_orders write_customers))
    other_scopes = OmniAuth::Shopify::ApiAccess.new(%w(write_images read_content))
    refute scopes.covers?(other_scopes)
  end

  def test_covers_is_falsy_for_sets_of_scopes_that_have_only_some_common_access
    scopes = OmniAuth::Shopify::ApiAccess.new(%w(write_products write_orders write_customers))
    other_scopes = OmniAuth::Shopify::ApiAccess.new(%w(write_products read_content))
    refute scopes.covers?(other_scopes)
  end

  def test_duplicate_scopes_resolve_to_one_scope
    scopes = OmniAuth::Shopify::ApiAccess.new(%w(read_orders read_orders read_orders read_orders))
    equivalent_scopes = OmniAuth::Shopify::ApiAccess.new(%w(read_orders))
    assert_equal equivalent_scopes, scopes
  end

  def test_to_s_outputs_scopes_as_a_comma_separated_list_without_implied_read_scopes
    serialized_scopes = "read_products,write_orders"
    expected_scopes = OmniAuth::Shopify::ApiAccess.new(%w(read_products read_orders write_orders))
    assert_equal expected_scopes.to_s, serialized_scopes
  end

  def test_to_a_outputs_scopes_as_an_array_of_strings_without_implied_read_scopes
    serialized_scopes = %w(read_products write_orders)
    expected_scopes = OmniAuth::Shopify::ApiAccess.new(%w(read_products read_orders write_orders))
    assert_equal expected_scopes.to_a, serialized_scopes
  end

  def test_creating_scopes_removes_extra_whitespace_from_scope_name_and_blank_scope_names
    deserialized_scopes = OmniAuth::Shopify::ApiAccess.new([' read_products', '  ', 'write_orders '])
    expected_scopes = OmniAuth::Shopify::ApiAccess.new(%w(read_products write_orders))
    serialized_scopes = deserialized_scopes.to_s
    assert_equal expected_scopes, OmniAuth::Shopify::ApiAccess.new(serialized_scopes)
  end

  def test_creating_scopes_from_a_string_works_with_a_comma_separated_list
    deserialized_scopes = OmniAuth::Shopify::ApiAccess.new("read_products,write_orders")
    expected_scopes = OmniAuth::Shopify::ApiAccess.new(%w(read_products write_orders))
    serialized_scopes = deserialized_scopes.to_s
    assert_equal expected_scopes, OmniAuth::Shopify::ApiAccess.new(serialized_scopes)
  end

  def test_using_to_s_from_one_scopes_to_construct_another_will_be_equal
    expected_scopes = OmniAuth::Shopify::ApiAccess.new(%w(read_products write_orders))
    assert_equal expected_scopes, OmniAuth::Shopify::ApiAccess.new(expected_scopes.to_s)
  end

  def test_using_to_a_from_one_scopes_to_construct_another_will_be_equal
    expected_scopes = OmniAuth::Shopify::ApiAccess.new(%w(read_products write_orders))
    assert_equal expected_scopes, OmniAuth::Shopify::ApiAccess.new(expected_scopes.to_a)
  end
end