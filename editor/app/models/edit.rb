class Edit < ActiveRecord::Base
  attr_accessible :definition, :synsetid, :members, :semlinks, :pos, :lexlinks
  serialize :members, Hash
  serialize :semlinks, Array
  serialize :lexlinks, Array

protected
  def members_check
    member.each do |m|
      errors.add(:member, "#{m} is no a valid member") unless true
    end
  end
  def semlinks_check
    semlink.each do |m|
      errors.add(:semlink, "#{m} is no a valid semlink") unless true
    end
  end
  def lexlinks_check
    lexlink.each do |m|
      errors.add(:lexlink, "#{m} is no a valid lexlink") unless true
    end
  end




end
