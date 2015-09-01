def sample_credentials
  {
    "test_mode"        => '1',
    "client_code"      => ENV['CLIENT_CODE'],
    "client_signature" => ENV['CLIENT_SIGNATURE']
  }.with_indifferent_access
end

def sample_shipment(number = "R#{rand(999999)}")
  {
    "id"=>number,
    "status"=>"complete",
    "channel"=>"spree",
    "email"=>"spree@example.com",
    "currency"=>"USD",
    "placed_on"=>"2014-02-03T17:29:15.219Z",
    "shipping_notes"=>"Please fit in large box",
    "no_ship_before"=>"2015-08-01T00:00:00+00:00",
    "must_ship_by"=>"2015-08-25T00:00:00+00:00",
    "totals"=>
    {"item"=>200,
     "adjustment"=>20,
     "tax"=>10,
     "shipping"=>10,
     "payment"=>220,
     "order"=>220},
     "items"=>
    [{"product_id"=>"QTRZIM03",
      "name"=>"QTRZIM03",
      "quantity"=>2,
      "price"=>100}],
      "adjustments"=>
    [{"name"=>"Tax", "value"=>10},
     {"name"=>"Shipping", "value"=>5},
     {"name"=>"Shipping", "value"=>5}],
    "shipping_address"=>
    {"firstname"=>"Joe",
     "lastname"=>"Smith",
     "address1"=>"1234 Awesome Street",
     "address2"=>"",
     "zipcode"=>"90210",
     "city"=>"Hollywood",
     "state"=>"California",
     "country"=>"US",
     "phone"=>"0000000000"},
     "billing_address"=>
    {"firstname"=>"Joe",
     "lastname"=>"Smith",
     "address1"=>"1234 Awesome Street",
     "address2"=>"",
     "zipcode"=>"90210",
     "state"=>"California",
     "country"=>"US",
     "phone"=>"0000000000"}
  }.merge(order_extra_fields).with_indifferent_access
end

def order_extra_fields
  {
    "shipping_method" => "US UPS Two Day"
  }
end
