class DummyModel < ActiveRecord::Base
  acts_as_essence ingredient_column: 'data'
end
