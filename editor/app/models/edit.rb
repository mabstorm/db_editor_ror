class Edit < ActiveRecord::Base
  attr_accessible :definition, :synsetid, :members, :semlinks, :pos
  serialize :members, Hash
  serialize :semlinks, Array

protected
  def members_check
    member.each do |m|
      errors.add(:member, "#{m} is no a valid mood") unless true
    end
  end
  def semlinks_check
    semlink.each do |m|
      errors.add(:semlink, "#{m} is no a valid mood") unless true
    end
  end



end
