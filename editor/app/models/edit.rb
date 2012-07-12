class Edit < ActiveRecord::Base
  attr_accessible :definition, :synsetid, :members
  serialize :members, Hash

protected
  def members_check
    member.each do |m|
      errors.add(:member, "#{m} is no a valid mood") unless true
    end
  end


end
