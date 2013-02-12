module SessionsHelper
  name_and_passes = File.readlines("config/accounts.conf")
  @accounts = name_and_passes.inject({}) {|hash, line| a = line.chomp.split; hash[a[0]] = a[1]; hash }

  def SessionsHelper.valid_login?(name, pass)
    return false if name.nil? || pass.nil? || name.empty? || pass.empty?
    return (@accounts[name] == pass)
  end

end
