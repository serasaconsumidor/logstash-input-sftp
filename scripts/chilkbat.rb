require "chilkat"

# The Chilkat API can be unlocked for a fully-functional 30-day trial by passing any
# string to the UnlockBundle method.  A program can unlock once at the start. Once unlocked,
# all subsequently instantiated objects are created in the unlocked state. 
# 
# After licensing Chilkat, replace the "Anything for 30-day trial" with the purchased unlock code.
# To verify the purchased unlock code was recognized, examine the contents of the LastErrorText
# property after unlocking.  For example:
glob = Chilkat::CkGlobal.new()

success = glob.UnlockBundle("Anything for 30-day trial")
if (success != true)
    puts glob.lastErrorText() + "\n";
    exit
end

status = glob.get_UnlockStatus()
if (status == 2)
    puts "Unlocked using purchased unlock code." + "\n";
else
    puts "Unlocked in trial mode." + "\n";
end

# The LastErrorText can be examined in the success case to see if it was unlocked in
# trial more, or with a purchased unlock code.
puts glob.lastErrorText() + "\n";

puts "dentro de process"

sftp = Chilkat::CkSFtp.new()

sucess = sftp.Connect("localhost", 2222)

if (sucess != true)
  puts sftp.lastErrorText() + "\n";
  exit
end

sucess = sftp.AuthenticatePw("ftpuser", "ftppass")

if (sucess != true)
  puts sftp.lastErrorText() + "\n";
  exit
end

sucess = sftp.InitializeSftp()

if (sucess != true)
  puts sftp.lastErrorText() + "\n";
  exit
end

puts "SUCESSO CABRON!"
