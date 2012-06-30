class Edit < ActiveRecord::Base
  attr_accessible :definition, :synsetid
  serialize :members, Hash
end
