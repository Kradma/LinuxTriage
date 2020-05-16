#!/bin/bash

##LiveInformation
LiveInformation(){
	echo"LiveInformation being recorded"
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

Dumps(){
	echo"Dumps being recorded"
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
	cp /etc/groups $dumpsPath/etc_groups
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
	gzip varLog.tar

	#get_mbr
	bootDisk=$(fdisk -l |grep -oP '\/dev\/[a-z]+(?=[0-9]+\s*\*)')
	dd if=$bootDisk of=$dumpsPath/mbr.raw bs=512 count=1
}


FileSystem(){
	echo"FileSystem being recorded"
	mkdir $currentPath/.results/FileSystem
	fileSystemPath=$currentPath/.results/FileSystem
	#get_all_files_info
	find / -type f -exec stat {} \; -execdir echo -n "Sha256: " \; -execdir bash -c 'echo $(sha256sum {})|sed "s/ .*//g"' \; -execdir echo -n " Magic: " \; -execdir bash -c 'echo $(file {})|sed "s/.* //g"' \; -execdir echo "" \; >> $fileSystemPath

}


CompressAndRemove(){
	tar -cvfz $currentPath/evidencias.tar.gz $currentPath/.results --remove-files
}

#main method
#Comprobamos que se ejecute como root
if [ "$EUID" -ne 0 ]
  then echo "Bro, this program will only run as root..."
  exit
fi

usage(){
	echo "Usage: $0 [--version <fast|full>] [--out <directory>"
}
while getopts ":version:out:" opt
do
	case $opt in
		version)
			version=${OPTARG}
			((version=="fast" || version=="full")) || usage
			;;
		out)
			out=${OPTARG}
			;;
		*)
			usage
			exit 1 ;;
	esac
done

#Set output directory
if [ -z "$out" ]
then
	currentPath=pwd
else
	currentPath=$out
fi
mkdir $currentPath/.results
echo "test1"
#select_execution_mode
if [ -z "$version" ]
then
	echo "[--version <fast|full>] is mandatory"
	exit 1
else
	if [ "$version" == "fast" ]
	then
		LiveInformation
		Dumps
	else
		LiveInformation
		Dumps
		FileSystem
	fi
if
CompressAndRemove