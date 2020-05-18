#!/bin/bash

#Gets information about the live sistem
LiveInformation(){
	echo -e "NOW: LiveInformation being recorded \n"
	##¿debería comprobar si netstat o ss, lo mismo con ip addr y ifconfig?
	mkdir $currentPath/.results/LiveInfo
	liveInfoPath=$currentPath/.results/LiveInfo
	#get_Processes
	ps -ewo %p,%P,%x,%t,%u,%c,%a >> $liveInfoPath/processes
	#get_kernel_version
	uname -a >> $liveInfoPath/kernel_version
	#get_os_info
	hostnamectl >> $liveInfoPath/hostnamectl
	#get_network_cards
	ip addr >> $liveInfoPath/ip_addr
	#get_hostname
	hostname >> $liveInfoPath/hostname
	#get_network_connection
	echo "####### ss -apetul #######" >> $liveInfoPath/network_connections
	ss -apetul >> $liveInfoPath/network_connections
	echo "\n" >> $liveInfoPath/network_connections
	echo "####### Plain ss #######" >> $liveInfoPath/network_connections
	ss >> $liveInfoPath/network_connections
	#get_logon
	last -Faixw >> $liveInfoPath/logon
	#get_handles
	lsof -R >> $liveInfoPath/handles
	#get_modules
	lsmod >> $liveInfoPath/handles
}

#Collects some important files
Dumps(){
	echo -e "NOW: Dumps being recorded \n"
	mkdir $currentPath/.results/Dumps
	dumpsPath=$currentPath/.results/Dumps
	#get_temp
	tar -czvf $dumpsPath/tmp_files.tar.gz /tmp
	#get_autoruns
	mkdir $dumpsPath/autoruns
	tar -czvf $dumpsPath/autoruns/dotDFiles.tar.gz /etc/*.d
	tar -czvf $dumpsPath/autoruns/cronFiles.tar.gz /etc/cron*
	tar -czvf $dumpsPath/autoruns/init.tar.gz /etc/init
	#get_passwd
	cp /etc/passwd $dumpsPath/etc_passwd
	#get_groups
	cp /etc/group $dumpsPath/etc_groups
	#get_etc_bashrc
	cp /etc/bash.bashrc $dumpsPath/etc_bashrc
	#get_etc_profile
	cp /etc/profile $dumpsPath/etc_profile
	
	#PERUSER get_ssh_known_hosts
	#cp /etc/profile $dumpsPath/

	#get_logs
	for file in $(find /var/log -maxdepth 1 -type f -size -10M);
	do 
		tar -rvf $dumpsPath/varLog.tar $file; 
	done; 
	gzip $dumpsPath/varLog.tar

	#get_mbr
	bootDisk=$(fdisk -l |grep -oP '\/dev\/[a-z]+(?=[0-9]+\s*\*)')
	dd if=$bootDisk of=$dumpsPath/mbr.raw bs=512 count=1
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
		else
			mkdir -p $currentPath/.results
			chown $(logname):$(logname) $currentPath
			echo "USUARIO:  $(logname)"
			LiveInformation
			Dumps
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
				FileSystem
			else
				mkdir -p $currentPath/.results
				chown $(logname):$(logname) $currentPath
				LiveInformation
				Dumps
				FileSyste
			fi
		else
			echo -e "ERROR: Wrong type of triage: \"$type\" does not exist \n"
			usage
		fi
	fi
	CompressAndRemove
	exit 1
fi
exit 1
