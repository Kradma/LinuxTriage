#!/bin/bash

#Gets information about the live sistem
LiveInformation(){
	echo -e "[INFO]: LiveInformation() started"
	##¿debería comprobar si netstat o ss, lo mismo con ip addr y ifconfig?
	mkdir $currentPath/.results/LiveInfo
	liveInfoPath=$currentPath/.results/LiveInfo

	echo -e "[INFO LiveInformation()]: Getting SYSTEM INFO"
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
	#get_System_diagnostic
	echo "####### dmesg #######" >> $liveInfoPath/dmesg
	dmesg >> $liveInfoPath/dmesg

	echo -e "[INFO LiveInformation()]: Getting NETWORK INFO"
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
	#get_routes
	echo "####### route || ip r #######" >> $liveInfoPath/routes
	(ip r || route ) >> $liveInfoPath/routes
	#get_neighbors
	echo "####### arp -v  || ip -s neigh #######" >> $liveInfoPath/neighbors
	(ip -s neigh || arp -v ) >> $liveInfoPath/neighbors
}

#Collects some important files
Dumps(){
	echo -e "\n[INFO]: Dumps() started"
	mkdir $currentPath/.results/Dumps
	dumpsPath=$currentPath/.results/Dumps

	echo -e "[INFO Dumps()]: Getting TEMPORARY FILES"
	###TEMPORARY FILES###
	#get_temp
	tar -czf $dumpsPath/tmp_files.tar.gz -C / tmp 
	tar -czf $dumpsPath/var_tmp_files.tar.gz -C / var/tmp

	echo -e "\n[INFO Dumps()]: Getting AUTORUNS"
	###AUTORUNS###
	#get_autoruns
	mkdir $dumpsPath/autoruns
	$(cd / && tar -czf $dumpsPath/autoruns/dotDFiles.tar.gz etc/*.d)
	$(cd / && tar -czf $dumpsPath/autoruns/cronFiles.tar.gz etc/cron*)
	tar -czf $dumpsPath/autoruns/init.tar.gz -C / etc/init/
	tar -czf $dumpsPath/autoruns/systemd.tar.gz -C / lib/systemd/system/
	cp /etc/rc.local $dumpsPath/autoruns/rc_local

	echo -e "\n[INFO Dumps()]: Getting SYSTEM FILES"
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

	echo -e "\n[INFO Dumps()]: Getting NETWORK FILES"
	###NETWORK FILES###
	#get_network_interfaces
	echo "####### /etc/network/interfaces #######" >> $dumpsPath/interfaces
	cat /etc/network/interfaces >>  $dumpsPath/interfaces
	#get_etc_hosts
	echo "####### /etc/hosts #######" >> $dumpsPath/hosts
	cat /etc/hosts >> $dumpsPath/hosts
	#get_etc_resolv.conf
	echo "####### /etc/resolv.conf #######" >> $dumpsPath/resolv_conf
	cat /etc/resolv.conf >> $dumpsPath/resolv_conf

	echo -e "\n[INFO Dumps()]: Getting /var/log folder"
	###LOGS###
	#get_logs
	for file in $(find /var/log -maxdepth 1 -type f -size -10M);
	do 
		tar -rf $dumpsPath/varLog.tar -C / $file 2>&1 | grep -v  "Removing leading"
	done; 
	gzip $dumpsPath/varLog.tar

	echo -e "\n[INFO Dumps()]: Getting MBR sector"
	###MBR###
	#get_mbr
	bootDisk=$(fdisk -l |grep -oP '\/dev\/[a-z]+(?=[0-9]+\s*\*)')
	dd if=$bootDisk of=$dumpsPath/mbr.raw bs=512 count=1
}

PerUserDumps(){
	echo -e "\n[INFO]: PerUserDumps started"
	mkdir $currentPath/.results/PerUserDumps
	perUserPath=$currentPath/.results/PerUserDumps
	users=$(ls /home)
	ls /home/ >> $perUserPath/user_list
	echo -e "[INFO PerUserDumps()]: Getting hiddenFiles"
	#get_user_files
	for user in $users;
	do
		mkdir $perUserPath/$user/
		find /home/$user -maxdepth 1 -type f -name '.*' -exec tar -rf $perUserPath/$user/hiddenFiles.tar {} \; 2>&1 | grep -v  "Removing leading"
		gzip $perUserPath/$user/hiddenFiles.tar
		$(cd / && tar -czf $perUserPath/$user/hiddenConfig.tar.gz home/$user/.config)
		cp /home/$user/.ssh/known_hosts $perUserPath/$user/ssh_known_hosts.txt
		cp /home/$user/.ssh/config $perUserPath/$user/ssh_config.txt
		#tar -czvf $perUserPath/$user/hiddenFiles.tar.gz /home/$user/.*
		#cd /home/$user && tar -cvzf $perUserPath/$user/hiddenFiles.tar.gz $(ls -pa /home/$user  | grep -v / |grep -ie "^\.[a-z]") && cd -
		crontab -u $user -l >> $perUserPath/$user/crontab.txt	
	done

}

#FileSystem listing
FileSystem(){
	echo -e "[INFO]: FileSystem being recorded \n"
	mkdir $currentPath/.results/FileSystem
	fileSystemPath=$currentPath/.results/FileSystem
	#get_all_files_info
	find / -type f -exec stat {} \; -execdir echo -n "Sha256: " \; -execdir bash -c 'echo $(sha256sum {})|sed "s/ .*//g"' \; -execdir echo -n " Magic: " \; -execdir bash -c 'echo $(file {})|sed "s/.* //g"' \; -execdir echo "" \; >> $fileSystemPath/fileSystemlog

}

usage(){
	echo "Usage: sudo $0 --type <fast|full> [--plugin <penquin> --out <FULL PATH directory>]" 1>&2;
	echo "-t, --type	sets the type of triage to execute" 1>&2;
	echo "-p, --plugin	sets the desired plugin to execute. Grabs choosen threat actor artifacts."
	echo "-o, --out 	sets the output directory" 1>&2;
	echo "-v, --version 	shows version and credits of the tool" 1>&2;
	echo "-h, --help 	shows this help" 1>&2;
	exit 1;
}

version(){
	echo "Pure linux triage tool: $0, Version: 2.5" 1>&2;
	echo "Developed by Carles C. (@Kradma087)" 1>&2;
	exit 1;
}

#Bonus
KnockKnock(){
	echo -e "[INFO]: Knocking penquins secret doors.\n"
	echo -e "\n[Penquin]: __we_are_happy__\n"
	mkdir $currentPath/.results/penquinsNest
	penquinPath=$currentPath/.results/penquinsNest

	##d0f208486c90384117172796dc07f256##
	##Waits for commands in a file placed at /var/tmp/task##
	cp /var/tmp/task $penquinPath/task_file 2>/dev/null

	##b4755c24e6a84e447c96b29ca6ed8633##
	##Tool that extracts the first and last 1Kb from a file.##
	##The data is writen in files with their names plus .head or .tail.##
	mkdir $penquinPath/headTailFiles/
	find / -type f -name \*.head -execdir cp {} $penquinPath/headTailFiles/ \; 2>/dev/null
	find / -type f -name \*.tail -execdir cp {} $penquinPath/headTailFiles/ \; 2>/dev/null

	echo -e "\n[Penquin]: Hiding complit...n\n"

	##4065d2a24240426f6e9912a22bbfbab5##
	##The malware checks for the /var/tmp/task* files, If these are empty,
	## It procures the information and forks.##
	cp /var/tmp/taskhost $penquinPath/taskhost_file 2>/dev/null
	cp /var/tmp/taskpid $penquinPath/taskpid_file 2>/dev/null
	cp /var/tmp/tasklog $penquinPath/tasklog_file 2>/dev/null
	cp /var/tmp/taskgid $penquinPath/taskgid_file 2>/dev/null
	##Then it saves logs at /var/tmp/.Xtmp01 and also it creates files ended with .xk###
	cp /var/tmp/.Xtmp01 $penquinPath/xtmp01_file 2>/dev/null 
	mkdir $penquinPath/xkFiles
	find / -type f -name \*.xk -execdir cp {} $penquinPath/xkFiles/ \; 2>/dev/null

	##14cce7e641d308c3a177a8abb5457019##
	##The malware is a compilation of the LOKI2 source code, it creates a file called loki.log##
	find / -type f -name loki.log -execdir cp {} $penquinPath/ \; 2>/dev/null 

	echo -e "\n[Penquin]: receving message\n"

	##7b86f40e861705d59f5206c482e1f2a5##
	##The malware checks for the file /var/tmp/gogo if it misses, the malware ends##
	cp /var/tmp/gogo $penquinPath/gogo_file 2>/dev/null

	##d8347b2e32086bd25d41530849472b8d##
	##Shell script to extract all uniq source and destination IP from RES.u and RES.s to the file "list".##
	find / -type f -name RES.u  -execdir cp {} $penquinPath/ \; 2>/dev/null
	find / -type f -name RES.s  -execdir cp {} $penquinPath/ \; 2>/dev/null
	find / -type f -name list  -exec tar -rvf $penquinPath/listFiles.tar {} \; 2>/dev/null
	gzip $penquinPath/listFiles.tar
	##35f87672e8b7cc4641f01fb4f2efe8c3##
	##Shell script that between others it creates a file called res.tar##
	find / -type f -name res.tar  -execdir cp {} $penquinPath/ \; 2>/dev/null

	echo -e "\n[Penquin]: open file for read\n"

	##67d9556c695ef6c51abf6fbab17acb3466e3149cf4d20cb64d6d34dc969b6502##
	##Hidden files used by penquin referer at leonardocompany.com paper##
	cp /tmp/.xdfg $penquinPath/xdfg_file 2>/dev/null
	cp /tmp/.sync.pid $penquinPath/sync_pid_file 2>/dev/null
	cp /root/.xfdshp1 $penquinPath/xfdshp1_file 2>/dev/null
	cp /root/.session $penquinPath/sesssion_file 2>/dev/null
	cp /root/.sess $penquinPath/sess_file 2>/dev/null
	cp /root/.hsperfdata $penquinPath/hsperfdata_file 2>/dev/null
	
	echo -e "\n[Penquin]: Connect successful....\n"

	##Why not getting all the hidden files in tmp and root##
	find /tmp -maxdepth 1 -type f  -name '.*' -execdir tar -rvf $penquinPath/hiddenTMPFiles.tar {} \;
	gzip $penquinPath/hiddenTMPFiles.tar
	find /root -maxdepth 1 -type f  -name '.*' -execdir tar -rvf $penquinPath/hiddenROOTFiles.tar {} \;
	gzip $penquinPath/hiddenROOTFiles.tar
	
	##God tool's are grep and find not Yara##
	find /home /tmp /etc /var /root ! -path . -type f -size -5000k -exec grep -Hal '__we_are_happy_\|VS filesystem\|remote filesystem!\|rem_fd:\|TREX_PID\|Z@@NM@@G_Y_FE\|supported only on ethernet/FDDI/token\||  size  |state|\|IPv6 address %s not supported' {} \; >>$penquinPath/grepedFilesList 2>/dev/null
	[ -s $penquinPath/grepedFilesList ] && {
		mkdir $penquinPath/grepedFiles;
		while IFS="" read -r p || [ -n "$p" ];
			do  cp "$p"  $penquinPath/grepedFiles/;
		done < $penquinPath/grepedList;
	}

	echo -e "\n[Penquin]: ...that's it. peace man :)\n"
	echo -e "[Penquin]: Done!\n"
}



#################
##UTIL FUNCTIONS#
#################
_banner(){
	printf '\033[8;30;100t'
	echo ""
	cat << EOF

	██╗     ██╗███╗   ██╗██╗   ██╗██╗  ██╗    ████████╗██████╗ ██╗ █████╗  ██████╗ ███████╗
	██║     ██║████╗  ██║██║   ██║╚██╗██╔╝    ╚══██╔══╝██╔══██╗██║██╔══██╗██╔════╝ ██╔════╝
	██║     ██║██╔██╗ ██║██║   ██║ ╚███╔╝        ██║   ██████╔╝██║███████║██║  ███╗█████╗  
	██║     ██║██║╚██╗██║██║   ██║ ██╔██╗        ██║   ██╔══██╗██║██╔══██║██║   ██║██╔══╝  
	███████╗██║██║ ╚████║╚██████╔╝██╔╝ ██╗       ██║   ██║  ██║██║██║  ██║╚██████╔╝███████╗
	╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝       ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
	                                                                                       
	██████╗ ██╗   ██╗    ██╗      █████╗ ██████╗ ███████╗██████╗                           
	██╔══██╗╚██╗ ██╔╝    ██║     ██╔══██╗██╔══██╗██╔════╝╚════██╗                          
	██████╔╝ ╚████╔╝     ██║     ███████║██████╔╝███████╗ █████╔╝                          
	██╔══██╗  ╚██╔╝      ██║     ██╔══██║██╔══██╗╚════██║██╔═══╝                           
	██████╔╝   ██║       ███████╗██║  ██║██████╔╝███████║███████╗                          
	╚═════╝    ╚═╝       ╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝                          
                                                                                                                                                                                                                                                                           
EOF
}

_directory_exists(){
		[ -d "$1" ] 
}

_show_parameters(){
	echo "The selected parameters are:"
	echo "[Type]: $1"
	echo "[Output]: $2"
	echo -e "[Plugin]: $3\n"
}


#Compress all and remove working directories
_compressAndRemove(){
	mv $currentPath/.results $currentPath/evidence
	tar -cvzf $currentPath/evidence.tar.gz  -C $currentPath/ evidence  --remove-files
	chown $(logname):$(logname) $currentPath/evidence.tar.gz
}


###############
##MAIN METHOD##
###############

_banner

unset out
unset opt
unset type
unset plugin

# Transform long options to short ones
for arg in "$@"; do
  shift
  case "$arg" in
    "--type")		set -- "$@" "-t" ;;
    "--out")		set -- "$@" "-o" ;;
    "--version")	set -- "$@" "-v" ;;
	"--help")		set -- "$@" "-h" ;;
	"--plugin")		set -- "$@" "-p" ;;
	"--"*)			usage;;
    *)				set -- "$@" "$arg"
  esac
done

OPTIND=1
while getopts ":t:p:o:vh" opt
do
	case "$opt" in
		t)
			type=${OPTARG}
			;;
		p)
			plugin=${OPTARG}
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

# Continue only allowed to root users bro
if [ "$EUID" -ne 0 ]
  then
  	echo -e "Bro, this program will only run as root...\n"
  	usage
fi

#Set output directory
if [ -z "$out" ]
then
	currentPath=$(pwd)
	mkdir $currentPath/.results
else
	currentPath=$out
	echo -e "[INFO]: Checking if directory $currentPath exists.\n"
	if _directory_exists $currentPath
	then
		mkdir $currentPath/.results
	else
		if [[ $currentPath == /* ]];
		then
			echo -e "[ERROR]: Given path does not exists: $currentPath\n"
			exit 1
		fi

		echo -e "[WARNING]: Creating $currentPath folder(s) in current path.\n"
		mkdir -p $currentPath/.results
		currentPath=$(pwd)"/"$currentPath
		echo -e "[INFO]: Giving permisions to $currentPath as user: $(logname)\n"
		chown $(logname):$(logname) $currentPath
	fi
fi

#select_execution_mode
if [ -z "$type" ]
then
	echo -e "[ERROR]: The parameter [--type <fast|full>] is mandatory \n"
	rmdir $currentPath/.results
	usage #Ends execution
fi


_show_parameters $type $currentPath $plugin
##Recognizing the proper type of triage
case "$type" in
		fast)
			echo -e "[INFO]: Executing $type triage.\n"
			LiveInformation
			Dumps
			PerUserDumps
			;;
		full)
			echo -e "[INFO]: Executing $type triage.\n"
			LiveInformation
			Dumps
			PerUserDumps
			FileSystem
			;;
		penquin)
			KnockKnock
			;;
		*)
			echo -e "[ERROR]: Wrong type of triage: \"$type\" does not exist \n"
			rmdir $currentPath/.results
			usage
			;;
esac

case "$plugin" in
		penquin)
			if [ "$type" == "penquin" ]; then
				echo -e "[Penquin]: Doing tricky things ah?. I'm not gonna do anything yet...\n"
			else
				KnockKnock
			fi
			;;
		"")
			echo -e "\n[INFO]: No plugin was selected.\n"
			;;
		*)
			echo -e "\n[WARNING]: Wrong type of plugin: \"$plugin\" does not exist."
			echo -e "[WARNING]: Doing nothing.\n"
			;;
esac

echo -e "[INFO]: Generating evidence package."
_compressAndRemove
exit 1