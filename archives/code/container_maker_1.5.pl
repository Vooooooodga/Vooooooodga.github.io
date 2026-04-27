#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use Time::Local;
use Getopt::Long;

my $exec_bin="$FindBin::Bin";
my $script_bin="$exec_bin/bin"; 

#container maker. support install R language, perl language and other softwares.
#Version 1.2.
#Written by Chao Fang. 07/29/2019.
#Email: cfang@lc-bio.com

#增加sif是否生成的开关。删除rsync2target,keep_cache_file和scp2target参数，改成界面输入的形式。
#Version 1.3.
#Written by Chao Fang. 08/13/2019.
#Email: cfang@lc-bio.com

#修正同步到集群时的端口号为50000。
#Version 1.4.
#Written by Chao Fang. 12/31/2021.
#Email: cfang@lc-bio.com

my ($container_dir);
my ($App_name,$based_sif,$Softwares_file,$Softwares_list,$yum_install,$pip_install,$pip3_install,$R_install_interactive,$perl_install_interactive,$perl_install,$login,$login_dir,$user_id,$development_mode,$files_in_out,$bind,$port);
my @errors = get_params("parameter_container_maker.txt");
if(exists ($errors[0])){
	print STDERR "Processing $0...\n";
	foreach my $str(@errors){
		print "$str\n";
	}
	print "Quitting...\n";
	exit;
}

# @errors = get_params_conf("$exec_bin/container.config");
# if(exists ($errors[0])){
	# print STDERR "Processing $0...\n";
	# foreach my $str(@errors){
		# print "$str\n";
	# }
	# print "Quitting...\n";
	# exit;
# } 

my $os_dir="/mnt/data1/prog1/Container/hub/Centos";
my $pwd=`pwd`;
chomp $pwd;

$container_dir=initPara($container_dir,"$pwd");

my $OS_ver=$1 if($based_sif=~/centos_(.+?)$/i);

if($OS_ver){
	my $os_sif="$os_dir/$OS_ver/sif/centos_$OS_ver.sif";
	#-----------------------------------------------------------------
	system("sudo singularity build --sandbox $container_dir/$App_name/ $os_sif");
}
else{#customed sif
	my $os_sif=$based_sif;
	#-----------------------------------------------------------------
	system("sudo singularity build --sandbox $container_dir/$App_name/ $os_sif.sif");
}

if($development_mode=~/^NO$/i){
	print STDERR "building pkgs of yum...started\n";

	if($yum_install ne "NA"){
		$yum_install=~s/,/ /g;
		install_pkgs("yum install -y $yum_install");
	}
	print STDERR "building pkgs of yum...done\n";

	print STDERR "building pkgs of pip...started\n";
	if($pip_install ne "NA"){
		$pip_install=~s/,/ /g;
		install_pkgs("pip install $pip_install");
	}
	print STDERR "building pkgs of pip...done\n";

	print STDERR "building pkgs of pip3...started\n";
	if($pip3_install ne "NA"){
		$pip3_install=~s/,/ /g;
		install_pkgs("pip3 install $pip3_install");
	}
	print STDERR "building pkgs of pip3...done\n";

	print STDERR "building pkgs of perl...started\n";
	if($perl_install_interactive=~/^YES$/i){
		install_pkgs("perl -MCPAN -e shell");
	}
	else{
		if($perl_install ne "NA"){
			$perl_install=~s/,/ /g;
			install_pkgs("perl -MCPAN -e \'install $perl_install\'");
		}
	}

	#cp perl packages into /usr/local/share/perl5.
	cp_perl_pkgs();
	print STDERR "building pkgs of perl...done\n";

	print STDERR "building pkgs of R...started\n";
	if($R_install_interactive=~/^YES$/i){
		install_pkgs("R");
		print STDERR "building pkgs of R...done\n";
	}
	else{
		print STDERR "building pkgs of R...skipped\n";
	}
	
	print STDERR "building pkgs of perl...done\n";

	print STDERR "copying files/dirs to inside OS...";
	if($files_in_out=~/^NA$/i){
		print STDERR "copying files/dirs skipped\n";
	}
	else{
		cp_files_in2out();
		print STDERR "copying files/dirs done\n";
	}

	print STDERR "building pkgs of R...done\n";

	my $app_sif="$container_dir/$App_name.sif";
	print STDERR "generating sif of $App_name...started\n";
	#system("SINGULARITY_LOCALCACHEDIR=/mnt/data1/tmp SINGULARITY_TMPDIR=/mnt/data1/tmp singularity build $app_sif $container_dir/$App_name/");
	if (-e $app_sif){
		system("sudo singularity build $app_sif $container_dir/$App_name/");
		print STDERR "generating sif done!\n";
	}
	else{
		print STDERR "Should I generate of $app_sif [N/y]? ";
		while(my $answer = <STDIN>){
			if ($answer =~ /^y/i){
				system("sudo singularity build $app_sif $container_dir/$App_name/");
				print STDERR "generating sif done!\n";
				last;
			}
			elsif($answer =~ /^N/i){
				print STDERR "generating sif skipped!\n";
				last;
			}
			else
			{
				print STDERR "Please enter [N/y]!\n";
			}
		}
	}
	
	print STDERR "Should I scp to login cluster [N/y]? ";
	while(my $answer = <STDIN>){
		if ($answer =~ /^y/i){
			scp2target($app_sif,$App_name);
			print STDERR "scp to login cluster done!\n";
			last;
		}
		elsif($answer =~ /^N/i){
			print STDERR "scp to login cluster skipped!\n";
			last;
		}
		else
		{
			print STDERR "Please enter [N/y]!\n";
		}
	}
	
	print STDERR "Should I keep cache files[N/y]? ";
	while(my $answer = <STDIN>){
		if ($answer =~ /^y/i){
			print STDERR "remove cache files skipped!\n";
			last;
		}
		elsif($answer =~ /^N/i){
			system("sudo trash $container_dir/$App_name/");
			print STDERR "remove cache files done!\n";
			last;
		}
		else{
			print STDERR "Please enter [N/y]!\n";
		}
	}

}
else{
	print STDERR "start development mode...";
	my $app_sif="$container_dir/$App_name.sif";
	if($bind=~/^NA$/){
		system("sudo singularity shell --writable --no-home $container_dir/$App_name/");
	}
	else{
		system("sudo singularity shell --bind $bind --writable --no-home $container_dir/$App_name/");
	}
	print STDERR "generating sif of $App_name...started\n";
	#system("SINGULARITY_LOCALCACHEDIR=/mnt/data1/tmp SINGULARITY_TMPDIR=/mnt/data1/tmp singularity build $app_sif $container_dir/$App_name/");
	if (-e $app_sif){
		system("SINGULARITY_LOCALCACHEDIR=/mnt/data1/tmp SINGULARITY_TMPDIR=/mnt/data1/tmp sudo singularity build $app_sif $container_dir/$App_name/");
		print STDERR "generating sif done!\n";
	}
	else{
		print STDERR "Should I generate of $app_sif [N/y]? ";
		while(my $answer = <STDIN>){
			if ($answer =~ /^y/i){
				system("SINGULARITY_LOCALCACHEDIR=/mnt/data1/tmp SINGULARITY_TMPDIR=/mnt/data1/tmp sudo singularity build $app_sif $container_dir/$App_name/");
				print STDERR "generating sif done!\n";
				last;
			}
			elsif($answer =~ /^N/i){
				print STDERR "generating sif skipped!\n";
				last;
			}
			else{
				print STDERR "Please enter [N/y]!\n";
			}
		}
	}
	
	print STDERR "Should I scp to login cluster [N/y]? ";
	while(my $answer = <STDIN>){
		if ($answer =~ /^y/i){
			scp2target($app_sif,$App_name);
			print STDERR "scp to login cluster done!\n";
			last;
		}
		elsif($answer =~ /^N/i){
			print STDERR "scp to login cluster skipped!\n";
			last;
		}
		else{
			print STDERR "Please enter [N/y]!\n";
		}
	}
	
	print STDERR "Should I keep cache files[N/y]? ";
	while(my $answer = <STDIN>){
		if ($answer =~ /^y/i){
			print STDERR "remove cache files skipped!\n";
			last;
		}
		elsif($answer =~ /^N/i){
			system("sudo trash $container_dir/$App_name/");
			print STDERR "remove cache files done!\n";
			last;
		}
		else{
			print STDERR "Please enter [N/y]!\n";
		}
	}
}

#=============================================================

sub install_pkgs{
	my ($cmd)=@_;
	#print STDERR "singularity exec --writable $container_dir/$App_name/ $cmd\n";
	system("sudo singularity exec --writable $container_dir/$App_name/ $cmd");

}

sub cp_perl_pkgs{
	my $container_perl_lib="$container_dir/$App_name/usr/local/share/perl5/";
	my @cpl_f=`ls $container_perl_lib`;
	my %cpl_f=();
	foreach my $cpl_f(@cpl_f){
		chomp $cpl_f;
		$cpl_f{$cpl_f}=1;
	}
	my $pkgs_dir="$os_dir/$OS_ver/pkgs";
	my @insf=`ls $pkgs_dir/perl5/`;
	foreach my $insf(@insf){
		chomp $insf;
		unless (exists $cpl_f{$insf}){
			print STDERR "cp -rf $pkgs_dir/perl5/$insf $container_dir/$App_name/usr/local/share/perl5/\n";
			`cp -rf $pkgs_dir/perl5/$insf $container_dir/$App_name/usr/local/share/perl5/`;
		}
	}
	
}

sub cp_files_in2out{
	my @files=split(/,/,$files_in_out);
	foreach my $files(@files){
		my ($in,$out)=split(/:/,$files);
		`cp -rf $in $container_dir/$App_name/$out` unless(-e "$container_dir/$App_name/$out");
	}
	
}

sub scp2target{
	my ($app_sif,$App_name)=@_;
	my $host_name=`hostname`;
	chomp $host_name;
	if($host_name ne $login){
		print STDERR "ssh -p $port $user_id\@$login \"if [ ! -d \"$login_dir\" ]; then mkdir -p $login_dir ; fi \"\n";
		`ssh -p $port $user_id\@$login \"if [ ! -d \"$login_dir\" ]; then mkdir -p $login_dir ; fi \"`;
		
		print STDERR "if [ \$(ssh -p $port $user_id\@$login \"ls $login_dir/$App_name.sif|wc -l|awk '{print \$1}'\") -eq 0 ];then scp -P $port -r $app_sif $user_id\@$login:$login_dir;fi\n";
		`if [ \$(ssh -p $port $user_id\@$login \"ls $login_dir/$App_name.sif|wc -l|awk '{print \$1}'\") -eq 0 ];then scp -P $port -r $app_sif $user_id\@$login:$login_dir;fi`;
		
		# print STDERR "scp -P $port -r $app_sif $user_id\@$login:$login_dir/\n";
		# system("scp -P $port -r $app_sif $user_id\@$login:$login_dir/");
	}
}

#-----------------------------------------------------------------
sub initPara{
	my ($in,$out)=@_;
	(!$in||$in eq "")?(return $out):(return $in);
}

sub get_params{
	my $paramfile_tmp=shift;
	my %paramfile_hash=();
	my @faults=();
	open (INF, "$paramfile_tmp" ) || die "cannot open parameter file $paramfile_tmp: $!\n";
	while(<INF>){
		next if ($_ =~ /^\#/);
		next unless ($_ =~ /=/);
		chomp $_;
		my($key, $value) = split('=', $_,2);
		$key=~s/\s//g;
		$value=~s/\s+$//;
		$value=~s/^\s+//;
		$paramfile_hash{$key} = $value;
	}
	close INF;
	$App_name  	     =$paramfile_hash{App_name};
	$based_sif       =$paramfile_hash{based_sif};
	$Softwares_file       =$paramfile_hash{Softwares_file};
	$Softwares_list       =$paramfile_hash{Softwares_list};
	$yum_install       =$paramfile_hash{yum_install};
	$pip_install       =$paramfile_hash{pip_install};
	$pip3_install       =$paramfile_hash{pip3_install};
	$R_install_interactive       =$paramfile_hash{R_install_interactive};
	$perl_install_interactive       =$paramfile_hash{perl_install_interactive};
	$perl_install       =$paramfile_hash{perl_install};
	$login       =$paramfile_hash{login};
	$login_dir       =$paramfile_hash{login_dir};
	$user_id       =$paramfile_hash{user_id};
	$development_mode       =$paramfile_hash{development_mode};
	$files_in_out       =$paramfile_hash{files_in_out};
	$bind       =$paramfile_hash{bind};
	$port       =$paramfile_hash{port};
	unless( $App_name){
		push (@faults,  "cannot find App_name: $App_name");
	}
	unless( $based_sif){
		push (@faults,  "cannot find based_sif: $based_sif");
	}
	unless( $yum_install){
		push (@faults,  "cannot find yum_install: $yum_install");
	}
	unless( $pip_install){
		push (@faults,  "cannot find pip_install: $pip_install");
	}
	unless( $pip3_install){
		push (@faults,  "cannot find pip3_install: $pip3_install");
	}
	unless( $R_install_interactive){
		push (@faults,  "cannot find R_install_interactive: $R_install_interactive");
	}
	unless( $perl_install_interactive){
		push (@faults,  "cannot find perl_install_interactive: $perl_install_interactive");
	}
	unless( $perl_install){
		push (@faults,  "cannot find perl_install: $perl_install");
	}
	unless( $login){
		push (@faults,  "cannot find login: $login");
	}
	unless( $port){
		push (@faults,  "cannot find port: $port");
	}
	unless( $login_dir){
		push (@faults,  "cannot find login_dir: $login_dir");
	}
	unless( $user_id){
		push (@faults,  "cannot find user_id: $user_id");
	}
	unless( $development_mode){
		push (@faults,  "cannot find development_mode: $development_mode");
	}
	unless( $files_in_out){
		push (@faults,  "cannot find files_in_out: $files_in_out");
	}
	unless( $bind){
		push (@faults,  "cannot find bind: $bind");
	}
	return @faults;			
}