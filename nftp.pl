#!/usr/local/bin/perl
# an ftp client simulator wrapped around scp


# include in configuration info
# specify here a list of aliases and ports in the hash @aliases, e.g.
#      $aliases{napier}=napier.pvl.edu.au:22
#      $aliases{clare}=localhost:3000

do "$ENV{HOME}/.nftprc";  

$cwd=".";
$port=22;   # default port for ssh

sub split_quoted
{
    my($i,$j,$quoted,@r);
    split //;
    for ($i=0, $j=0, $quoted=0, @r=(); $i<=$#_; $i++)
    {
	if ($_[$i] eq "\"") {$quoted=!$quoted; next;}
	if ($_[$i] eq " " && !$quoted) {$j++; next;}
	if ($_[$i] eq "\n" && !$quoted) {last;}
	$r[$j].=$_[$i];
    }
    return @r;
}

for (print "ftp>"; <STDIN>; print "ftp>")
{
    if (/^exit/ || /^quit/) {last;}
    if (/^open/)
    { 
	($dummy,$rhost)=split;
	if (!exists($aliases{$rhost})) {exec "ftp -i -n $rhost";}
	print "Connected to $rhost\n";
	print "220 $rhost FTP server ready.\n";
	($rhost,$port)=split /:/,$aliases{$rhost};
    }
    if (/^user/)
    {
	($dummy,$uname)=split;
	print "230 User $uname logged in.\n";
    }
    if (/^hash/) {print "Hash mark printing on (1024 bytes/hash mark).\n";}
    if (/^type binary/) {print "200 Type set to I.\n";}
    if (/^type ascii/) {print "200 Type set to A.\n";}
    if (/^pwd/)
    {
	chomp($pwd=qx{ssh -p $port -l $uname $rhost pwd 2>&1});
	print "257 $pwd is current directory.\n";
    }
    if (/^cd/)  {($dummy,$cwd)=split_quoted;}
    if (/^lcd/)  {($dummy,$lwd)=split_quoted; chdir $lwd;}
    if (/^get/)  
    {
	($dummy,$source,$dest)=split_quoted; 
	if ($source!~m"^/") {$source="$cwd/$source"};
	if (length($dest)==0) {$dest=".";}
	print "200 PORT command successful.\n";
	print "150 Opening BINARY mode data connection for '$source'\n\n";
	system("scp -P $port -q $rhost:$source $dest >/dev/null 2>&1");
	print "226 Transfer complete.\n";
    }
    if (/^put/)
    {
	($dummy,$source,$dest)=split_quoted; 
	if ($dest!~m"^/") {$dest="$cwd/$dest";}
	print "200 PORT command successful.\n";
	print "150 Opening BINARY mode data connection for '$dest'\n\n";
	system("scp -P $port -q $source $rhost:$dest >/dev/null 2>&1");
	print "226 Transfer complete.\n";
    }
    if (/^ls/)
    {
	($dummy,$source,$dest)=split_quoted;
	$result=qx{ssh -p $port $rhost 'cd $cwd; ls $source' 2>&1};
	print "200 PORT command successful.\n";
	print "150 Opening ASCII mode data connection for '/bin/ls'.\n";
	if (length($dest)==0) {print $result;}
	else 
	{
	    open dest,">$dest";
	    print dest $result;
	    close dest
	}
	print "226 Transfer complete.\n";
    }
    if (/^rename/)
    {
	($dummy,$source,$dest)=split_quoted;
	$result=qx{ssh -p $port $rhost 'cd $cwd; mv $source $dest' 2>&1};
	print "250 RNTO command successful.\n";
    }
    if (/^delete/)
    {
	($dummy,$source)=split_quoted;
	$result=qx{ssh -p $port $rhost 'cd $cwd; rm $source' 2>&1};
	print "250 DELE command successful.\n";
    }
    if (/^mkdir/)
    {
	($dummy,$source)=split_quoted;
	$result=qx{ssh -p $port $rhost 'cd $cwd; mkdir $source' 2>&1};
	print "250 MKDIR command successful.\n";
    }
    if (/^chmod/)
    {
	($dummy,$mode,$source)=split_quoted;
	$result=qx{ssh -p $port $rhost 'cd $cwd; chmod $mode $source' 2>&1};
	print "250 CHMOD command successful.\n";
    }
}
