#!/bin/bash

#Gets information about the live sistem
LiveInformation(){
	echo -e "NOW: LiveInformation() started \n"
	##¿debería comprobar si netstat o ss, lo mismo con ip addr y ifconfig?
	mkdir $currentPath/.results/LiveInfo
	liveInfoPath=$currentPath/.results/LiveInfo

	echo -e "NOW: LiveInformation() getting SYSTEM INFO \n"
	###SYSTEM INFO###
	#get_Processes
	echo "####### ps -ewo %p,%P,%x,%t,%u,%c,%a #######" >> $liveInfoPath/processes
	ps -ewo %p,%P,%x,%t,%u,%c,%a >> $liveInfoPath/processes
	#get_kernel_version
	echo "####### uname -a #######" >> $liveInfoPath/kernel_versio
	uname -a >> $liveInfoPath/kernel_version
	#get_os_info
	echo "####### hostnamectl #######" >> $liveInfoPath/hostnamectl
	hostnamectl >> $liveInfoPath/hostnamectl
	#get_logon
	echo "####### last -Faixw #######" >> $liveInfoPath/logon
	last -Faixw >> $liveInfoPath/logon
	#get_handles
	echo "####### lsof -R #######" >> $liveInfoPath/handles
	lsof -R >> $liveInfoPath/handles
	#get_modules
	echo "####### lsmod #######" >> $liveInfoPath/modules
	lsmod >> $liveInfoPath/modules

	echo -e "NOW: LiveInformation() getting NETWORK INFO \n"
	###NETWORK INFO###
	#get_network_cards
	echo "####### (ip addr || ifconfig -a) #######" >> $liveInfoPath/ip_addr
	(ip addr || ifconfig -a) >> $liveInfoPath/ip_addr
	#get_hostname
	echo "####### hostname #######" >> $liveInfoPath/hostname
	hostname >> $liveInfoPath/hostname
	#get_network_connection
	echo "####### ss/netstat -apetul #######" >> $liveInfoPath/network_connections
	(ss -apetul|| netstat -apetul) >> $liveInfoPath/network_connections
	echo "\n" >> $liveInfoPath/network_connections
	echo "####### ss/netstat -putona #######" >> $liveInfoPath/network_connections
	(ss -putona|| netstat -putona) >> $liveInfoPath/network_connections
	echo "\n" >> $liveInfoPath/network_connections
	echo "####### Plain ss/netstat #######" >> $liveInfoPath/network_connections
	(ss || netstat) >> $liveInfoPath/network_connections
	#get_System_diagnostic
	echo "####### dmesg #######" >> $liveInfoPath/dmesg
	dmesg >> $liveInfoPath/dmesg
	#get_routes
	echo "####### route || ip r #######" >> $liveInfoPath/routes
	(route || ip r) >> $liveInfoPath/routes
	#get_neighbors
	echo "####### arp -v  || ip -s neigh #######" >> $liveInfoPath/neighbors
	(arp -v || ip -s neigh) >> $liveInfoPath/neighbors
}

#Collects some important files
Dumps(){
	echo -e "NOW: Dumps() started \n"
	mkdir $currentPath/.results/Dumps
	dumpsPath=$currentPath/.results/Dumps

	echo -e "NOW: Dumps() getting /tmp folder\n"
	#get_temp
	tar -czvf $dumpsPath/tmp_files.tar.gz /tmp

	echo -e "NOW: Dumps() getting AUTORUNS \n"
	###AUTORUNS###
	#get_autoruns
	mkdir $dumpsPath/autoruns
	tar -czvf $dumpsPath/autoruns/dotDFiles.tar.gz /etc/*.d
	tar -czvf $dumpsPath/autoruns/cronFiles.tar.gz /etc/cron*
	tar -czvf $dumpsPath/autoruns/init.tar.gz /etc/init
	tar -czvf $dumpsPath/autoruns/systemd.tar.gz /lib/systemd/system/
	cp /etc/rc.local $dumpsPath/autoruns/rc_local

	echo -e "NOW: Dumps() getting SYSTEM info FILES\n"
	###SYSTEM FILES###
	#get_passwd
	echo "####### /etc/passwd #######" >> $dumpsPath/etc_passwd
	cat /etc/passwd >> $dumpsPath/etc_passwd
	#get_groups
	echo "####### /etc/group #######" >> $dumpsPath/etc_groups
	cat /etc/group >> $dumpsPath/etc_groups
	#get_etc_bashrc
	echo "####### /etc/bash.bashrc #######" >> $dumpsPath/etc_bashrc
	cat /etc/bash.bashrc >> $dumpsPath/etc_bashrc
	#get_etc_profile
	echo "####### /etc/profile #######" >> $dumpsPath/etc_profile
	cat /etc/profile >> $dumpsPath/etc_profile
	#get_etc_sudoers
	echo "####### /etc/sudoers #######" >> $dumpsPath/etc_sudoers
	cat /etc/sudoers >> $dumpsPath/etc_sudoers
	#get_os_release
	echo "####### /etc/os-release #######" >> $dumpsPath/os_release
	cat /etc/os-release >> $dumpsPath/os_release

	echo -e "NOW: Dumps() getting NETWORK info FILES\n"
	###NETWORK FILES###
	#get_network_interfaces
	echo "####### /etc/network/interfaces #######" >> $dumpsPath/interfaces
	cat /etc/network/interfaces >>  $dumpsPath/interfaces
	#get_etc_host
	echo "####### /etc/host #######" >> $dumpsPath/hosts
	cat /etc/host >> $dumpsPath/hosts
	#get_etc_resolv.conf
	echo "####### /etc/resolv.conf #######" >> $dumpsPath/resolv_conf
	cat /etc/resolv.conf >> $dumpsPath/resolv_conf

	
	#PERUSER get_ssh_known_hosts
	#cp /etc/profile $dumpsPath/

	echo -e "NOW: Dumps() getting /var/log folder\n"
	###LOGS###
	#get_logs
	for file in $(find /var/log -maxdepth 1 -type f -size -10M);
	do 
		tar -rvf $dumpsPath/varLog.tar $file; 
	done; 
	gzip $dumpsPath/varLog.tar

	echo -e "NOW: Dumps() getting MBR sector\n"
	###MBR###
	#get_mbr
	bootDisk=$(fdisk -l |grep -oP '\/dev\/[a-z]+(?=[0-9]+\s*\*)')
	dd if=$bootDisk of=$dumpsPath/mbr.raw bs=512 count=1
}

PerUserDumps(){
	echo -e "NOW: Per user dumps being recorded \n"
	mkdir $currentPath/.results/PerUserDumps
	perUserPath=$currentPath/.results/PerUserDumps
	users=$(ls /home)
	ls /home/ >> $perUserPath/user_list
	
	echo -e "NOW: PerUserDumps() getting hiddenFiles\n"
	#get_user_files
	for user in $users;
	do
		mkdir $perUserPath/$user/
		find /home/$user -type f -maxdepth 1 -name '.*' -exec tar -rvf $perUserPath/$user/hiddenFiles.tar {} \;
		gzip $perUserPath/$user/hiddenFiles.tar
		#tar -czvf $perUserPath/$user/hiddenFiles.tar.gz /home/$user/.*
		#cd /home/$user && tar -cvzf $perUserPath/$user/hiddenFiles.tar.gz $(ls -pa /home/$user  | grep -v / |grep -ie "^\.[a-z]") && cd -
		crontab -u $user -l >> $perUserPath/$user/crontab	
	done

}

#FileSystem listing
FileSystem(){
	echo -e "NOW: FileSystem being recorded \n"
	mkdir $currentPath/.results/FileSystem
	fileSystemPath=$currentPath/.results/FileSystem
	#get_all_files_info
	find / -type f -exec stat {} \; -execdir echo -n "Sha256: " \; -execdir bash -c 'echo $(sha256sum {})|sed "s/ .*//g"' \; -execdir echo -n " Magic: " \; -execdir bash -c 'echo $(file {})|sed "s/.* //g"' \; -execdir echo "" \; >> $fileSystemPath/fileSystemlog

}

#Compress all, remove malware, give permisions
CompressAndRemove(){
	mv $currentPath/.results $currentPath/evidence
	tar -cvzf $currentPath/evidence.tar.gz  -C $currentPath/ evidence  --remove-files
	chown $(logname):$(logname) $currentPath/evidence.tar.gz
}

usage(){
	echo "Usage: sudo $0 --type <fast|full> [--out <directory>]" 1>&2;
	echo "-t, --type	sets the type of triage to execute" 1>&2;
	echo "-o, --out 	sets the output directory" 1>&2;
	echo "-v, --version 	shows version and credits of the tool" 1>&2;
	echo "-h, --help 	shows this help" 1>&2;
	exit 1;
}

version(){
	echo "Native linux triage tool: $0, Version: 1.0" 1>&2;
	echo "Developed by @C_rl_s087" 1>&2;
	exit 1;
}

_directory_exists(){
		[ -d "$1" ] 
}

_show_parameters(){
	echo "Selected parameters:"
	echo "Type of triage: $1"
	echo -e "Output directory: $2\n"
}

#Bonus
KnockKnock(){
	echo "Knock knock knocking on penquins door"
	exit 1;
}



#main method
#Comprobamos que se ejecute como root
if [ "$EUID" -ne 0 ]
  then
  	echo -e "Bro, this program will only run as root...\n"
  	usage
fi

unset out
unset opt
unset type

# Transform long options to short ones
for arg in "$@"; do
  shift
  case "$arg" in
    "--type")		set -- "$@" "-t" ;;
    "--out")		set -- "$@" "-o" ;;
    "--version")	set -- "$@" "-v" ;;
	"--help")	set -- "$@" "-h" ;;
	"--"*)			usage;;
    *)				set -- "$@" "$arg"
  esac
done

OPTIND=1
while getopts ":t:o:vh" opt
do
	case "$opt" in
		t)
			type=${OPTARG}
			;;
		o)
			out=${OPTARG}
			;;
		v)
			version
			;;
		h)
			usage
			;;
		*)
			if [ "$OPTERR" != 1 ] || [ "${optspec:0:1}" = ":" ]; then
			    echo "Non-option argument: '-${OPTARG}'" >&2
			fi
			usage
			;;
	esac
done
shift "$((OPTIND-1))"

#Set output directory
if [ -z "$out" ]
then
	currentPath=$(pwd)
else
	currentPath=$(pwd)"/"$out
fi

#select_execution_mode
if [ -z "$type" ]
then
	echo -e "ERROR: The parameter [--type <fast|full>] is mandatory \n"
	usage
else
	if [ "$type" == "fast" ]
	then
		_show_parameters $type $currentPath
		if _directory_exists $currentPath
		then
			mkdir $currentPath/.results
			LiveInformation
			Dumps
			PerUserDumps
		else
			mkdir -p $currentPath/.results
			chown $(logname):$(logname) $currentPath
			echo "USUARIO:  $(logname)"
			LiveInformation
			Dumps
			PerUserDumps
		fi
	else
		if [ "$type" == "full" ]
		then
			echo "[ \"$type\" == \"full\" ]"
			_show_parameters $type $currentPath
			if _directory_exists $currentPath;
			then
				mkdir $currentPath/.results
				LiveInformation
				Dumps
				PerUserDumps
				FileSystem
			else
				mkdir -p $currentPath/.results
				chown $(logname):$(logname) $currentPath
				LiveInformation
				Dumps
				PerUserDumps
				FileSyste
			fi
		else
			if [ "$type" == "penquin" ]
			then
				echo "[ \"$type\" == \"full\" ]"
				_show_parameters $type $currentPath
				if _directory_exists $currentPath;
				then
					mkdir $currentPath/.results
					KnockKnock
				else
					mkdir -p $currentPath/.results
					KnockKnock
				fi
			else
				echo -e "ERROR: Wrong type of triage: \"$type\" does not exist \n"
				usage
			fi
		fi
	fi
	CompressAndRemove
	exit 1
fi
exit 1
