<#
Markinson Monthly Health Check

.Introduction
    This script is to provide the Database Administrator quick information
    about the database performance and system informtion.

.Description
    Using various of scripts to gather information and action if required.

.Notes
    Directory : C:\mopro_backup\systemcheck\Mark_Monthly_Check\
    File Name : Monthly_Mark_Check.ps1
    Author    : Markinson Business Solutions 

.Enhancements
    1. Colour code background colour if information is not within specs
    2. Include information regarding the database performance within the email
    3. etc... Can be added later

#>


<#
This information is to set the enviroment for where the database resides
 *** Change the directory as required ****
 Example: If the database is installed in "D" Drive Change the following
 from "C:\" to "D:\"
#>

$env:DLC = "C:\Progress\OpenEdge114"
$env:WRKDIR = "C:\OpenEdge\WRK114"
$env:OEM = "C:\Progress\oemgmt"
$env:OEMWRKDIR = "C:\OpenEdge\wrk_oemgmt"
$env:PATH = $env:DLC + "\BIN;" + $env:DLC + "\PERL\BIN;" + $env:PATH
$env:LIB = $env:DLC + "\LIB;" + $env:LIB
cd $env:WRKDIR

#Get infomration about the local user and the computer name

$user = $([Environment]::UserName)
$machinename =& hostname.exe

#############################################################
##### This will need to be configured before you deploy #####
############# Or the script it will not work! ###############
#############################################################

#Search for the live database name (database also known as)
$dbaka = 'mp6'
$clientaka = 'DEM'

#Allocate the path for where the databae resides
#with older sites theres a change it can either be "db" or "dtb"
$dbpath = "C:\mopro\$dbaka\db"

<#
The scripts will require a text file to allow "proenv" to run the
required scripts to obtain database informtion. The path for the
scripts
#>
$proenvpath = "C:\mopro_backup\systemcheck\Mark_Monthly_Check"

#############################################
######## Begin Healthcheck Metrics   ########
#############################################

#Line 1 - Get the current date
$now = get-date

#Line 2 - Display the clients name which is predefined under $clientaka

#Line 3 - Obtain the OS information
$osinfo = Get-CimInstance Win32_OperatingSystem | Select Caption
$bits = [Environment]::Is64BitProcess
if ($bits -eq $true) {
    $bits = "64bit"
} 
else {
    $bits = "32bit"
    
}

#Line 4 - Drive Table purpose is code to list logical drives mediatype 12 - Fixed hard disk media
$drivetable = Get-WmiObject win32_logicaldisk -Filter 'MediaType = "12"' -ea stop |
   Select-Object @{l='ServerName';e= {$_.__SERVER} },
                 @{l='DriveLetter';e = {$_.Name} },
                 # In case we want this to display later @{l='DriveType';e = {$_.MediaType} },
                 @{l='FreeSize(GB)';e = {$_.freespace / 1GB -as [int]} },
                 @{l='TotalSize(GB)';e = {$_.Size / 1GB -as [int]} },
                 @{l='PercentUsed';e = {[Math]::Round($_.FreeSpace / $_.Size * 100,2)} }

#Line 5 - Get the EDM details
$edmkeyloc = "\\$machinename\c$\Users\All Users\Application Data\Optio\OECI\7.7\etc\"
$edmexist = Test-Path $edmkeyloc
#$edmexist
If ($edmexist -eq $True) {
$edmkey = Get-Content "$edmkeyloc\eci.key"
}
Else {
$edmkey = "No EDM Installed"
}
#TRANSFORM Check for transform
$transformLoc = "c:\Program Files (x86)\Bottomline Technologies\Transform Foundation Server\config\"
$edmexist = Test-Path $transformLoc
#$edmexist
If ($edmexist -eq $True) {
$edmkey = Get-Content "$transformLoc\branded-version-string.txt"
}
Else {
$edmkey = "No EDM Installed"
}
#$edmkey

#Line 6 - Get the last time the server was restarted
$uptime = (Get-ChildItem -Hidden -File \\$machinename\c$ -Filter '*page*').LastWriteTime

#Line 7 - Obtain how many users are licensed for MoPro
$userfileexist = Test-Path "$proenvpath\usercheck.bat"
If ($userfileexist -eq $True) {
Start-Process -FilePath $proenvpath\usercheck.bat -WorkingDirectory "$proenvpath" -ArgumentList "/q" -Wait -WindowStyle Hidden
$usersqty = Get-Content $proenvpath\users.txt | select -first 1 -skip 3
}
Else {
$usersqty = "Unobtainable"
}

#Line 8 - to check mopro verision and include the hotfix
$moproloc = "\\$machinename\c$\Program Files (x86)\Markinson\MomentumPro Server 3.1\prg\"
$moproexist = Test-Path $moproloc
#$moproexist
If ($moproexist -eq $True) {
$moprohtfx = (Get-Content "$moproloc\version.xml").Substring(46,2)
$mopropatch = (Get-Content "$moproloc\version.xml").Substring(13,7)
$prodbvers = (Get-Content "$moproloc\version.xml").Substring(32,4)
$moprovers = $mopropatch+"."+$moprohtfx
}
Else {
$moprovers = "Unobtainable"
$prodbvers = "Unobatinable"
}

#Line 9 - Get the data sizes of the log files in KB's
#Live log sizes in KB
$logarray=[System.Collections.ArrayList]@()
$logarray.Add((Get-Item ($dbpath + "\live.lg")).Length/1KB -as [int]) >$null 2>&1
$logarray.Add((Get-Item ($dbpath + "\markin.lg")).Length/1KB -as [int]) >$null 2>&1

#Line 10 - Get the CPU information
$cpu = (Get-WmiObject win32_processor -EA SilentlyContinue | Measure-Object -property LoadPercentage -Average | Select Average | % {$_.Average / 100}).ToString("P")


#Line 11 - Get the RAM information
$mem = Get-WmiObject win32_OperatingSystem -EA SilentlyContinue 
$mem = (($mem.TotalVisibleMemorySize - $mem.FreePhysicalMemory) / $mem.TotalVisibleMemorySize).ToString("P")

<#

PROENV SCRIPTS FOR DATABASE ADMIN INFORMATION

#>

#Line 12 - Displaying shared memory in the Progress Database using proenv
$answermem = & cmd /C "promon $dbpath\live < $proenvpath\answerfilemem.txt"
$sharemem = ($answermem -match "Shared Memory" -split "  ")[1]

#Line 13 - Dispalying buffer hits in the Progress Database using proenv
$ansbuffhit = & cmd /C "promon $dbpath\live < $proenvpath\answerfilebuffers.txt"
$buffhits = ($ansbuffhit -match "Buffer Hits" -split "\D+(\d+)")[1]

#Line 14 - Displaying last full backup in the Progress Database using proenv
$ansBackup = & cmd /C "promon $dbpath\live < $proenvpath\answerfilebackup.txt"
$lfbackup = ($ansBackup -match "Most recent Full Backup:      ").substring(35,14)
$lastbackup = [datetime]$lfbackup

#Line 15 - Displaying the Database freepsace and Extent information
$freedbspace = Get-Content "$proenvpath\zsareachk.log"
$totalDBsize = ($freedbspace -match "Total Phys").TrimStart('                        Total Physical Database Size:  ')
#Search for Data Areas and report back required values
$areaPercs = @()
for ($i = 0; $i -lt $freedbspace.length; $i++)
    {
        if ([regex]::ismatch($freedbspace[$i],"Data Area"))
        {
            $snapObject = new-object system.Management.Automation.PSObject
            $snapObject | add-member -membertype noteproperty -name "DataArea" -value $freedbspace[$i].Substring(22,1)
            $snapObject | add-member -membertype noteproperty -name "%Full" -value $freedbspace[$i+1].Substring(21,5) 
            $areaPercs += $snapObject
        }
}

#Line 16 - Progres database Fragmentation
#$livetab = & cmd /C "proutil $dbpath\live -C tabanalys" # 2> $null 
#$fragave = ($livetab -cmatch "Totals:").Substring(106,4)

#Line 17 - Last Test Update 
#will need to look into
$testupdate = Get-Content $proenvpath\refresh.txt | select -first 1 -skip 3

#Line 18 - Web services if exists versio?
$webmods = Get-ChildItem -Path 'C:\Program Files (x86)\Markinson\WebOnline Services*\**' -Filter version.xml -Recurse
# Load Verison numbers only
if ($webmods -eq $null) {
    $webvers = "Not Installed"
} 
else {
    $webvers = (Get-Content $webmods).TrimStart('<VERSION ID="').TrimEnd('"/>')
    
}

#Line 19 - Mobilty if exist version?
$mobileMods = Get-ChildItem -Path 'C:\Program Files (x86)\Markinson\Mobility*\**' -Filter version.xml -Recurse
# Load Verison numbers only
if ($mobileMods -eq $null) {
    $mobileVers = "Not Installed"
} 
else {
    $mobileVers = (Get-Content $mobileMods | select -first 1 -skip 1).TrimStart('<version id="').TrimEnd('"/>')
}


#Line 20 - After imaging if exists?
$aiStatus = & cmd /C "proutil $dbpath\live -C describe"
$aiEnabled = $aiStatus | select-string -Pattern 'After'
if ($aiEnabled -eq $null) {
    $aiEnabled = "Disabled"
} 
else {
    $aiEnabled = "Enabled"
    
}

# Need to look into what is it?

#Line 21 - DR NONE/YES?
# check for dr license in progress.cfg - C:\Progress\OpenEdge114
$drEnabled = $progCfg | Select-String -Pattern 'Replication'
if ($drEnabled -eq $null) {
    $drEnabled = "Not Installed"
} 
else {
    $drEnabled = "Installed"
    
}


#########################################
######## Make Report in HTML table ######
#########################################
# add 12 month cycling of report collation

#HTML colour codes
#Markinson Spot Colors
$markBlue = "#009DDC"
$markGrey = "#B6B8BA"
$markYellow = "#FFD24F"
$markLgreen = "#EBE72A"
$markLaqua = "#47C3D3"
$markOrange = "#F8971D"
$markDgreen = "#75C044"
$markDaqua = "#008DA8"
$markPink = "#B41E8E"
$markPurple = "#6E298D"

# REPORT TITLE AND HEADERS OF COLUMNS
$table = "<HTML><HEAD><TITLE>Proactive System Review</TITLE></HEAD><BODY><p align=Center><font size=6 face=Verdana color=#009DDC><B>Markinson Proactive System Review - $clientaka</B></font></p></tr>"
# Remove report pull time form header area
# $table += "<p align=Center><font face=Verdana color=Green size=3><b>Last pulled : $now EST</b></font></P>"
$table +="<p align=Center><table BORDER=1 width=2500 cellspacing=0 cellpadding=3>"
$table +="<tr>"
$table +="<th bgcolor=$markBlue colspan=1 width=100><p align=center><b><font face=Verdana size=2 color=WHITE>Date/Time</font></b></p></th>"
$table +="<th bgcolor=$markBlue colspan=1 nowrap=false><p align=center><b><font face=Verdana size=2 color=WHITE>DB Name</font></b></p></th>"
$table +="<th bgcolor=$markBlue colspan=1 nowrap=false><p align=center><b><font face=Verdana size=2 color=WHITE>OS Info</font></b></p></th>"
$table +="<th bgcolor=$markBlue colspan=1 nowrap=false><p align=center><b><font face=Verdana size=2 color=WHITE>Server Drive(s)</font></b></p></th>"
$table +="<th bgcolor=$markBlue colspan=1 nowrap=false><p align=center><b><font face=Verdana size=2 color=WHITE>EDM</font></b></p></th>"
$table +="<th bgcolor=$markBlue colspan=1 width=100><p align=center><b><font face=Verdana size=2 color=WHITE>Uptime</font></b></p></th>"
$table +="<th bgcolor=$markBlue colspan=1 width=75><p align=center><b><font face=Verdana size=2 color=WHITE>MoPro Users</font></b></p></th>"
$table +="<th bgcolor=$markBlue colspan=1 width=75><p align=center><b><font face=Verdana size=2 color=WHITE>MoPro Version</font></b></p></th>"
$table +="<th bgcolor=$markBlue colspan=1 width=75><p align=center><b><font face=Verdana size=2 color=WHITE>OE Version</font></b></p></th>"
$table +="<th bgcolor=$markBlue colspan=1 width=75><p align=center><b><font face=Verdana size=2 color=WHITE>Logs</font></b></p></th>"
$table +="<th bgcolor=$markBlue colspan=1 width=75><p align=center><b><font face=Verdana size=2 color=WHITE>CPU Load</font></b></p></th>"
$table +="<th bgcolor=$markBlue colspan=1 width=75><p align=center><b><font face=Verdana size=2 color=WHITE>MEM Load</font></b></p></th>"
$table +="<th bgcolor=$markBlue colspan=1 width=75><p align=center><b><font face=Verdana size=2 color=WHITE>DB Shared Mem</font></b></p></th>"
$table +="<th bgcolor=$markBlue colspan=1 width=75><p align=center><b><font face=Verdana size=2 color=WHITE>DB Buffer Hits</font></b></p></th>"
$table +="<th bgcolor=$markBlue colspan=1 width=100><p align=center><b><font face=Verdana size=2 color=WHITE>DB Recent BackUps</font></b></p></th>"
$table +="<th bgcolor=$markBlue colspan=1 nowrap=false><p align=center><b><font face=Verdana size=2 color=WHITE>DB Free Space</font></b></p></th>"
$table +="<th bgcolor=$markBlue colspan=1 nowrap=false><p align=center><b><font face=Verdana size=2 color=WHITE>DB Frag</font></b></p></th>"
$table +="<th bgcolor=$markBlue colspan=1 nowrap=false><p align=center><b><font face=Verdana size=2 color=WHITE>TestDB Last Update</font></b></p></th>"
$table +="<th bgcolor=$markBlue colspan=1 nowrap=false><p align=center><b><font face=Verdana size=2 color=WHITE>WebMods</font></b></p></th>"
$table +="<th bgcolor=$markBlue colspan=1 nowrap=false><p align=center><b><font face=Verdana size=2 color=WHITE>Mobility</font></b></p></th>"
$table +="<th bgcolor=$markBlue colspan=1 nowrap=false><p align=center><b><font face=Verdana size=2 color=WHITE>After Image</font></b></p></th>"
$table +="<th bgcolor=$markBlue colspan=1 nowrap=false><p align=center><b><font face=Verdana size=2 color=WHITE>DR Status</font></b></p></th>"
$table +="</tr>"



<#
#if statement to see show if buffer hits are out of the threshold
<#if($buffhits -ge 90) {
$table +="<th bgcolor=$markBlue colspan=1 width=100><p align=center><b><font face=Verdana size=2 color=WHITE>PDB Buffer Hits</font></b></p></th>"
}

else {
$table +="<th bgcolor=$markYellow colspan=1 width=100><p align=center><b><font face=Verdana size=2 color=WHITE>PDB Buffer Hits</font></b></p></th>"
}

#if statement to see recent backups are less then a day
<#if($lastbackup -lt $now.AddDays(-1)) {
$table +="<th bgcolor=$markyellow colspan=1 width=100><p align=center><b><font face=Verdana size=2 color=WHITE>PDB Recent BackUps</font></b></p></th>"
}

else {$table +="<th bgcolor=$markblue colspan=1 width=100><p align=center><b><font face=Verdana size=2 color=WHITE>PDB Recent BackUps</font></b></p></th>"
}


#if statement to see if DB free space is above 80%


#>





#Populate Table
$badcomp = @()

#Services current known production servers & filter inclusion / exclusions via active driectory for later use
#$servicesfilter = Get-ADComputer -Filter {(name -like "*emp-nb-23*") -and (name -notlike "*01*") -or (name -like "*swsi*") -and (name -notlike "*01*")}
$servicesfilter = $machinename
$servicesSVCinc = "*AdobeARM*", "*Diag*", "*DNS*","*gpsvc*"
$servicesSVCexc = "*PerfSvc"

# Add Servers to Table
$CompList = $machinename # | select -ExpandProperty Name
foreach ($c in $CompList) {

   Try {
     
     <# TRAFFIC LIGHT SYSTEM FOR LATER USE LEAVE OUT
     # $services = Get-Service -ComputerName $c -Name $servicesSVCinc -Exclude $servicesSVCexc
     # $statuscolor = 'Green'
     # $statuscolor = "#F8971D" # blue spot
     # $statuscolor = "#F8971D"

     If ($services.Status -eq 'Stopped') {
     $statuscolor = 'Red'
     }
     #>

     # REPORT METRIC POPULATION
     $table +="<tr bgcolor=WHITE>
     <td align=center><FONT COLOR=$markBlue face=Verdana size=2><b>"+$now+"</b></td>
     <td align=center><FONT COLOR=$markBlue face=Verdana size=2><b><a href='slx:ticket/tIZH7A6004TT'>"+$clientaka+"</a></td>
     <td align=center width=200><FONT COLOR=$markBlue face=Verdana size=2><b>"+$drivetable.ServerName+" "+$osinfo.Caption+" "+$bits+"</td>
     <td align=center width=200><FONT COLOR=$markBlue face=Verdana size=2><b>"+$drivetable.DriveLetter+" Free(GB):"+$drivetable.'FreeSize(GB)'+" Total(G):"+$drivetable.'TotalSize(GB)'+" Used "+$drivetable.PercentUsed+"%"+"</td>
     <td align=center><FONT COLOR=$markBlue face=Verdana size=2><b>"+$edmkey+"</td>
     <td align=center><FONT COLOR=$markBlue face=Verdana size=2><b>"+$uptime+"</td>
     <td align=center><FONT COLOR=$markBlue face=Verdana size=2><b>"+$usersqty+"</td>
     <td align=center><FONT COLOR=$markBlue face=Verdana size=2><b>"+$moprovers+"</td>
     <td align=center><FONT COLOR=$markBlue face=Verdana size=2><b>"+$prodbvers+"</td>
     <td align=center><FONT COLOR=$markBlue face=Verdana size=2><b>"+"Live: "+$logarray[0]+"KB Markin: "+$logarray[1]+"KB"+"</td>
     <td align=center><FONT COLOR=$markBlue face=Verdana size=2><b>"+$cpu+"</td>
     <td align=center><FONT COLOR=$markBlue face=Verdana size=2><b>"+$mem+"</td>
     <td align=center><FONT COLOR=$markBlue face=Verdana size=2><b>"+$sharemem+"</td>
     <td align=center><FONT COLOR=$markBlue face=Verdana size=2><b>"+$buffhits+" %"+"</td>
     <td align=center><FONT COLOR=$markBlue face=Verdana size=2><b>"+$lastbackup+"</td>
     <td align=center width=250><FONT COLOR=$markBlue face=Verdana size=2><b>"+$areaPercs[0]+" "+$areaPercs[1]+" DBSIZE: "+$totalDBsize+"</td> 
     <td align=center><FONT COLOR=$markBlue face=Verdana size=2><b>"+$fragave+"</td>
     <td align=center><FONT COLOR=$markBlue face=Verdana size=2><b>"+$testupdate+"</td>
     <td align=center><FONT COLOR=$markBlue face=Verdana size=2><b>"+$webvers+"</td>
     <td align=center><FONT COLOR=$markBlue face=Verdana size=2><b>"+$mobileVers+"</td>
     <td align=center><FONT COLOR=$markBlue face=Verdana size=2><b>"+$aiEnabled+"</td>
     <td align=center><FONT COLOR=$markBlue face=Verdana size=2><b>"+$drEnabled+"</td>
     </FONT></tr>"       
   }   

   Catch {
     $badcomp += $c
   }

}


# End the table for next months
$table +="</table>"

<# Table summary and any missed servers
$table +="<font size=2 face=Bodoni MT color=#003333><B>`nThe following servers could not be reached they were not interested in talking to us today and should be checked: </B></font><br>"
$table +="<font size=2 face=Bodoni MT color=#003333><B>Servers to Check : </B></font>$badcomp<br>"
$table += "<font size=2 face=Bodoni MT color=#003333><B>Report run on host: </B></font>$machinename<br>"
$table += "<font size=2 face=Bodoni MT color=#003333><B>Report run by user : </B></font>$user<br>"
#>

# Replace Table in htm file
#$table>$answerscpath\MarkinsonHealthReviewDEM.htm
# Append to Table in htm file - if we wish to keep records in single file
$table>>$proenvpath\MarkinsonHealthReview$clientaka.htm
$file = "$proenvpath\MarkinsonHealthReview$clientaka.htm"
$atthtm = new-object Net.Mail.Attachment($file)
#Add-Content $answerscpath\MarkinsonHealthReviewDEM.htm $table

# Add File creation date if older than 12 months back it up 



##########################################################		
################ Send Report on Email ####################
##########################################################				
<#
SMTP add list of known providers & logic test isp? 
ISP	Outgoing Mail Server 	                    Authentication?
AAPT :	           "mail.aapt.net.au"	 
Bigpond :	       "mail.bigpond.com"	        None required.
Blink Internet :   "mail.blink.m2.com.au"	 
Dodo :	           "smtp.dodo.com.au"	 
iiNet :	           "mail.iinet.net.au"	 
Internode :	       "mail.internode.on.net"	    Use same details as incoming.
iPrimus :	       "smtp.iprimus.com.au"	 
OntheNet :         "mail.onthenet.com.au"	 
Optusnet :         "mail.optusnet.com.au"	 
Ozemail :          "smtp.ozemail.com.au"	 
People Telecom :   "smtp.syd.people.net.au"     (NSW)	 
Three Mobile 3G :  "smtp.three.com.au"	 
TPG :	           "mail.tpg.com.au"	 
Virgin Mobile 3G:  "smtp.virginbroadband.com.au"	 
Vodafone 3G:	   "smtp.vodafone.net.au"	
#>

<#

$emailserver = "mail.markinson.com.au"
#Place holder email from name
$emailfrom = "jonathan.kirkwood@markinson.com.au"
# Choose Recipients
$emailto = "jonathan.kirkwood@markinson.com.au"
$messagesubject = "Proactive System Review $clientaka"
#attach htm to email
				
$message = New-Object System.Net.Mail.MailMessage $emailfrom, $emailto
# To add additional recipient vie the System.Net.Mail.MailMessage method
#$message.To.Add( "add.person@markinson.com.au")
#$message.To.Add( "jason.fay@markinson.com.au")
$message.subject = $messagesubject
$message.isbodyhtml = $true
$message.body = Get-Content $answerscpath\MarkinsonHealthReview$clientaka.htm
$message.Attachments.Add($atthtm)
#create and send email
$email = New-Object Net.Mail.SmtpClient($emailServer)
$email.send($message)
$atthtm.Dispose();
$message.Dispose();
#################### End Email #########################


#>