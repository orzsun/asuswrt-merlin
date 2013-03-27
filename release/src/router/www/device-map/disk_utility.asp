﻿<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta HTTP-EQUIV="Pragma" CONTENT="no-cache">
<meta HTTP-EQUIV="Expires" CONTENT="-1">
<link rel="shortcut icon" href="images/favicon.png">
<link rel="icon" href="images/favicon.png">
<title></title>
<link href="../form_style.css" rel="stylesheet" type="text/css" />
<link href="../NM_style.css" rel="stylesheet" type="text/css" />
<style>
a:link {
	text-decoration: underline;
	color: #FFFFFF;
}
a:visited {
	text-decoration: underline;
	color: #FFFFFF;
}
a:hover {
	text-decoration: underline;
	color: #FFFFFF;
}
a:active {
	text-decoration: none;
	color: #FFFFFF;
}
#updateProgress_bg{
	margin-top:5px;
	width:97%;
	background:url(/images/quotabar_bg_progress.gif);
	background-repeat: repeat-x;
}
.font_style{
	font-family:Verdana,Arial,Helvetica,sans-serif;

}
</style>
<script language="JavaScript" type="text/javascript" src="/jquery.js"></script>
<script>
var diskOrder = parent.getSelectedDiskOrder();
var pools = parent.computepools(diskOrder, "name");
var diskmon_status = '<% nvram_get("diskmon_status"); %>';
var diskmon_freq_time = '<% nvram_get("diskmon_freq_time"); %>';

var _apps_pool_error = '<% apps_fsck_ret(); %>';
if(_apps_pool_error != '')
	var apps_pool_error = eval(_apps_pool_error);
else
	var apps_pool_error = [[""]];

var usb_pool_error = ['<% nvram_get("usb_path1_pool_error"); %>', '<% nvram_get("usb_path2_pool_error"); %>'];

var set_diskmon_time = "";
var progressBar;
var timer;
var diskmon_freq_row = diskmon_freq_time.split('&#62');
var $j = jQuery.noConflict();

function initial(){
	document.getElementById("t0").className = "tab_NW";
	document.getElementById("t1").className = "tabclick_NW";

	load_schedule_value();
	freq_change();
	
	check_status(apps_pool_error);
	check_status2(usb_pool_error);

}

function freq_change(){
	if(document.form.diskmon_freq.value == 0){
		document.getElementById('date_field').style.display="none";
		document.getElementById('week_field').style.display="none";
		document.getElementById('time_field').style.display="none";
		document.getElementById('schedule_date').style.display="none";
		document.getElementById('schedule_week').style.display="none";
		document.getElementById('schedule_time').style.display="none";		
		document.getElementById('schedule_frequency').style.display="none";	
		document.getElementById('schedule_desc').style.display="none";			
	}
	else if(document.form.diskmon_freq.value == 1){
		document.getElementById('date_field').style.display="";	
		document.getElementById('week_field').style.display="none";
		document.getElementById('time_field').style.display="";
		document.getElementById('schedule_date').style.display="";
		document.getElementById('schedule_week').style.display="none";
		document.getElementById('schedule_time').style.display="";		
		document.getElementById('schedule_frequency').style.display="";		
		document.getElementById('schedule_desc').style.display="";
	}
	else if(document.form.diskmon_freq.value == 2){
		document.getElementById('date_field').style.display="none";
		document.getElementById('week_field').style.display="";
		document.getElementById('time_field').style.display="";
		document.getElementById('schedule_date').style.display="none";
		document.getElementById('schedule_week').style.display="";
		document.getElementById('schedule_time').style.display="";		
		document.getElementById('schedule_frequency').style.display="";	
		document.getElementById('schedule_desc').style.display="";	
	}
	else{
		document.getElementById('date_field').style.display="none";
		document.getElementById('week_field').style.display="none";
		document.getElementById('time_field').style.display="";
		document.getElementById('schedule_date').style.display="none";
		document.getElementById('schedule_week').style.display="none";
		document.getElementById('schedule_time').style.display="";		
		document.getElementById('schedule_frequency').style.display="";	
		document.getElementById('schedule_desc').style.display="";	
	}
	show_schedule_desc();
}

function show_schedule_desc(){
	var array_week = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
	var array_freq = ["", "Monthly", "Weekly", "Daily"];
	
	if(document.form.freq_mon.value == 1 || document.form.freq_mon.value == 21 || document.form.freq_mon.value == 31)
		document.getElementById('schedule_date').innerHTML = document.form.freq_mon.value + "st";
	else if(document.form.freq_mon.value == 2 || document.form.freq_mon.value == 22)
		document.getElementById('schedule_date').innerHTML = document.form.freq_mon.value + "nd";
	else if(document.form.freq_mon.value == 3 || document.form.freq_mon.value == 23)
		document.getElementById('schedule_date').innerHTML = document.form.freq_mon.value + "rd";
	else
		document.getElementById('schedule_date').innerHTML = document.form.freq_mon.value + "th";
		
	document.getElementById('schedule_week').innerHTML = " " + array_week[document.form.freq_week.value];
	document.getElementById('schedule_time').innerHTML = document.form.freq_hour.value + ":00";
	document.getElementById('schedule_frequency').innerHTML = array_freq[document.form.diskmon_freq.value];
}

function apply_schedule(){
	if(progressBar >= 1 && progressBar <= 100 ){
		alert("Disk scanning now. Please wait for it to complete.");
		return false;
	}
	else{
		set_diskmon_time = document.form.freq_mon.value+">"+document.form.freq_week.value+">"+document.form.freq_hour.value;
		document.form.diskmon_freq_time.value = set_diskmon_time;
		document.form.diskmon_force_stop.disabled = true;
		document.getElementById('loadingIcon_apply').style.display = "";
		document.form.action_script.value = "restart_diskmon";
		document.form.submit();
	}
}

function stop_diskmon(){
	//document.form.diskmon_freq.disabled = true;
	document.form.diskmon_freq_time.disabled = true;
	//document.form.diskmon_policy.disabled = true;
	document.form.diskmon_usbport.disabled = true;
	document.form.diskmon_part.disabled = true;
	document.form.diskmon_force_stop.disabled = false;
	document.form.diskmon_force_stop.value = "1";
	document.form.submit();
}

function gen_port_option(){
	var diskmon_usbport = '<% nvram_get("diskmon_usbport"); %>';
	var Beselected = 0;

	free_options(document.form.diskmon_usbport);
	for(var i = 0; i < foreign_disk_interface_names().length; ++i){
		if(foreign_disk_interface_names()[i] == diskmon_usbport)
			Beselected = 1;
		else
			Beselected = 0;

		add_option(document.form.diskmon_usbport, decodeURIComponent(foreign_disk_model_info()[i]), foreign_disk_interface_names()[i], Beselected);
	}

	gen_part_option();
}

function gen_part_option(){
	var diskmon_part = '<% nvram_get("diskmon_part"); %>';
	var Beselected = 0;
	var disk_port = document.form.diskmon_usbport.value;
	var disk_num = -1;

	free_options(document.form.diskmon_part);
	for(var i = 0; i < foreign_disk_interface_names().length; ++i){
		if(foreign_disk_interface_names()[i] == disk_port){
			disk_num = i;
			break;
		}
	}
	
	if(disk_num == -1){
		alert("System Error!");
		return;
	}

	for(var i = 0; i < pool_devices().length; ++i){
		if(pool_devices()[i] == diskmon_part)
			Beselected = 1;
		else
			Beselected = 0;

		if(per_pane_pool_usage_kilobytes(i, disk_num) > 0)
			add_option(document.form.diskmon_part, pool_names()[i], pool_devices()[i], Beselected);
	}
}

function go_scan(){
	var str = "During scanning process, all disk activities will be stopped, do you want to scan it now";
		
	if(!confirm(str)){
		document.getElementById('scan_status_field').style.display = "";
		document.getElementById('progressBar').style.display = "none";
		return false;
	}
	scan_manually();
	document.getElementById('loadingIcon').style.display = "";
}
function show_loadingBar_field(){
	document.getElementById('loadingIcon').style.display = "none";
	showLoadingUpdate();
	progressBar = 1;
	document.getElementById('scan_status_field').style.display = "none";
	document.getElementById('progressBar').style.display = "";		
	parent.document.getElementById('ring_USBdisk_'+diskOrder).style.display = "";
	parent.document.getElementById('ring_USBdisk_'+diskOrder).style.backgroundImage = "url(/images/New_ui/networkmap/backgroud_move_8P_2.0.gif)";
	parent.document.getElementById('ring_USBdisk_'+diskOrder).style.backgroundPosition = '0% 2%';
}

function showLoadingUpdate(){
	document.getElementById('btn_scan').style.display = "none";
	document.getElementById('btn_abort').style.display = "";
	
	$j.ajax({
    	url: '/disk_scan.asp',
    	dataType: 'script',
    	error: function(xhr){
    		showLoadingUpdate();
    	},
    	success: function(){
				document.getElementById("updateProgress").style.width = progressBar+"%";
				if(scan_status == 1 ){	// To control message of scanning status
					if(progressBar >= 5)
						progressBar =5;
						
					document.getElementById('scan_message').innerHTML = "Initializing disk scanning...";												
				}	
				else if(scan_status == 2){
					if(progressBar <= 5)
						progressBar = 6;
					else if (progressBar >= 15)	
						progressBar = 15;
				
					document.getElementById('scan_message').innerHTML = "Unmounting disk...";								
				}
				else if(scan_status == 3){
					if(progressBar <= 15)
						progressBar = 16;
					else if (progressBar >= 40)	
						progressBar = 40;
						
					document.getElementById('scan_message').innerHTML = "Disk scanning ...";					
				}	
				else if(scan_status == 4){
					if(progressBar <= 40)
						progressBar = 41;
					else if (progressBar >= 90)	
						progressBar = 90;
						
					document.getElementById('scan_message').innerHTML = "Disk Re-Mounting...";					
				}
				else if(scan_status == 5){
					if(progressBar <= 90)
						progressBar = 91;
				
					document.getElementById('scan_message').innerHTML = "Finishing disk scanning...";				
				}
			if(progressBar > 100){
				document.getElementById('btn_scan').style.display = "";
				document.getElementById('btn_abort').style.display = "none";
				document.getElementById('scan_status_field').style.display = "";
				document.getElementById('progressBar').style.display = "none";
				disk_scan_status();
				document.form.diskmon_freq.disabled = false;
				document.form.diskmon_freq_time.disabled = false;
				//document.form.diskmon_policy.disabled = false;
				document.form.diskmon_usbport.disabled = false;
				document.form.diskmon_part.disabled = false;
				document.form.diskmon_force_stop.disabled = false;
				return false;
			}		
			document.getElementById('progress_bar_no').innerHTML = progressBar+"%";
			progressBar++;			
			timer = setTimeout("showLoadingUpdate();", 100);
		}
	});
	
}

function abort_scan(){
	clearTimeout(timer);
	document.getElementById('scan_message').innerHTML = "Disk scan will be stopped soon ...";
	document.getElementById('progress_bar_no').innerHTML = progressBar + "%";	
	document.getElementById('loadingIcon').style.display = "";
	stop_diskmon();
	setTimeout("document.getElementById('loadingIcon').style.display = 'none'", 3000);	
	setTimeout('document.getElementById(\'btn_scan\').style.display = ""', 3000);
	setTimeout('document.getElementById(\'btn_abort\').style.display = "none"', 3000);		
	setTimeout('document.getElementById(\'progressBar\').style.display  = "none"', 3000);			
	setTimeout('disk_scan_status("")',3000);
}

function disk_scan_status(){
	$j.ajax({
    	url: '/disk_scan.asp',
    	dataType: 'script',
    	error: function(xhr){
    		disk_scan_status();
    	},
    	success: function(){
				check_status(flag);
				check_status2(usb_pool_error);
  		}
  });
}

function get_disk_log(){
	$j.ajax({
		url: '/disk_fsck.xml',
		dataType: 'xml',
		error: function(xhr){
			alert("Fail to get the log of fsck!");
		},
		success: function(xml){
			$j('#textarea_disk0').html($j(xml).find('disk1').text());
			$j('#textarea_disk1').html($j(xml).find('disk2').text());
		}
	});

	if(parent.getDiskPort(diskOrder) == "2")
		document.getElementById("textarea_disk1").style.display = "";
	else
		document.getElementById("textarea_disk0").style.display = "";
}

function check_status(flag){
	document.getElementById('scan_status_field').style.display = "";
	parent.document.getElementById('ring_USBdisk_'+diskOrder).style.display = "";
	parent.document.getElementById('ring_USBdisk_'+diskOrder).style.backgroundImage = "url(/images/New_ui/networkmap/white_04.gif)";
	parent.document.getElementById('iconUSBdisk_'+diskOrder).style.backgroundImage = "url(/images/New_ui/networkmap/USB_2.png)";	
	parent.document.getElementById('iconUSBdisk_'+diskOrder).style.backgroundPosition = '0% -103px';
	parent.document.getElementById('iconUSBdisk_'+diskOrder).style.position = "absolute";
	parent.document.getElementById('iconUSBdisk_'+diskOrder).style.marginTop = "0px";
	if(navigator.appName.indexOf("Microsoft") >= 0)
		parent.document.getElementById('iconUSBdisk_'+diskOrder).style.marginLeft = "0px";
	else	
		parent.document.getElementById('iconUSBdisk_'+diskOrder).style.marginLeft = "33px";
	
	if(flag.length == 0){
		document.getElementById('disk_init_status').style.display = "";
		document.getElementById('problem_found').style.display = "none";
		document.getElementById('crash_found').style.display = "none";
		document.getElementById('scan_status_image').src = "/images/New_ui/networkmap/normal.png";
	}
	else{
		var i, j, ret;
		for(i = 0, ret = 0; i < pools.length; ++i){
			for(j = 0; j < flag.length; ++j){
				if(pools[i] == flag[j][0]){
					ret += parseInt(flag[j][1]);
				}
			}
		}
		if(ret == 0){	
			document.getElementById('disk_init_status').style.display = "none";
			document.getElementById('problem_found').style.display = "";
			document.getElementById('crash_found').style.display = "none";
			document.getElementById('scan_status_image').src = "/images/New_ui/networkmap/blue.png";
			parent.document.getElementById('ring_USBdisk_'+diskOrder).style.backgroundPosition = '0% 50%';
			parent.document.getElementById('iconUSBdisk_'+diskOrder).style.backgroundPosition = '0px -103px';
		}
		else if(ret == 1){	
			document.getElementById('disk_init_status').style.display = "none";
			document.getElementById('problem_found').style.display = "none";
			document.getElementById('crash_found').style.display = "";
			document.getElementById('scan_status_image').src = "/images/New_ui/networkmap/red.png";
			parent.document.getElementById('ring_USBdisk_'+diskOrder).style.backgroundPosition = '0% 101%';
			parent.document.getElementById('iconUSBdisk_'+diskOrder).style.backgroundPosition = '0% -201px';
		}
		get_disk_log();
	}
}

function check_status2(usb_error){
	if(usb_error[parseInt(parent.getDiskPort(diskOrder))-1] == "1"){
		document.getElementById('disk_init_status').style.display = "none";
		document.getElementById('problem_found').style.display = "none";
		document.getElementById('crash_found').style.display = "";
		document.getElementById('scan_status_image').src = "/images/New_ui/networkmap/red.png";
		parent.document.getElementById('ring_USBdisk_'+diskOrder).style.backgroundPosition = '0% 101%';
		parent.document.getElementById('iconUSBdisk_'+diskOrder).style.backgroundPosition = '0% -201px';
	}
}

function load_schedule_value(){
	for(var i=0; i<3; i++){
		if(diskmon_freq_row[i] == "" || typeof(diskmon_freq_row[i]) == "undefined")
			diskmon_freq_row[i] = "1";
	}

	document.form.freq_mon.value = diskmon_freq_row[0];
	document.form.freq_week.value = diskmon_freq_row[1];
	document.form.freq_hour.value = diskmon_freq_row[2];
}

function scan_manually(){
	document.form.diskmon_freq.disabled = true;
	document.form.diskmon_freq_time.disabled = true;
	//document.form.diskmon_policy.disabled = false;
	//document.form.diskmon_usbport.disabled = true;
	//document.form.diskmon_part.disabled = true;
	document.form.diskmon_force_stop.disabled = true;
	document.form.diskmon_usbport.value = parent.getDiskPort(diskOrder);
	
	document.form.action_script.value = "start_diskscan";
	document.form.submit();
}

</script>
</head>
<iframe name="hidden_frame" id="hidden_frame" width="0" height="0" frameborder="0" scrolling="no"></iframe>

<body class="statusbody" onload="initial();">
<form name="form" method="post" action="/start_apply.htm" target="hidden_frame">
<input type="hidden" name="next_page" value="/device-map/disk_utility.asp">
<input type="hidden" name="action_mode" value="apply">
<input type="hidden" name="action_script" value="restart_diskmon">
<input type="hidden" name="action_wait" value="1">
<input type="hidden" name="diskmon_force_stop" value="<% nvram_get("diskmon_force_stop"); %>" >
<input type="hidden" name="diskmon_freq_time" value="<% nvram_get("diskmon_freq_time"); %>">
<input type="hidden" name="diskmon_policy" value="disk">
<input type="hidden" name="diskmon_usbport" value="<% nvram_get("diskmon_usbport"); %>">
<input type="hidden" name="diskmon_part" value="">
<table height="30px;">
	<tr>
		<td>		
			<table width="100px" border="0" align="left" style="margin-left:5px;" cellpadding="0" cellspacing="0">
			<td>
					<div id="t0" class="tabclick_NW" align="center" style="font-weight: bolder;margin-right:2px; width:100px;" onclick="location.href='disk.asp'">
						<span style="cursor:pointer;font-weight: bolder;">Information</span>
					</div>
				</td>
			<td>
					<div id="t1" class="tab_NW" align="center" style="font-weight: bolder;margin-right:2px; width:100px;" onclick="location.href='disk_utility.asp'">
						<span style="cursor:pointer;font-weight: bolder;">Disk Utility</span>
					</div>
				</td>
			</table>
		</td>
	</tr>
</table>

<table  width="313px;"  align="center"  style="margin-top:-8px;margin-left:3px;" cellspacing="5">
  <tr >
    <td style="background-color:#4D595D">
		<div id="scan_status_field" style="margin-top:10px;">
			<table>
				<tr class="font_style">
					<td width="40px;" align="center">
						<img id="scan_status_image" src="/images/New_ui/networkmap/normal.png">
					</td>
					<td id="disk_init_status" >
						Click "Scan" to check if your hard drive is heathly.
					</td>
					<td id="problem_found" style="display:none;">
						Disk scan process finished, please check the detail information as below.
					</td>
					<td id="crash_found" style="display:none;">
						We have found files cracked in your hard drive, please safely remove it and use a computer to fix it.
					</td>
				</tr>
			</table>	
		</div>
		<div id="progressBar" style="margin-left:9px;;margin-top:10px;display:none">
			<div id="scan_message"></div>
			<div id="updateProgress_bg"  >
				<div>
					<span id="progress_bar_no" style="position:absolute;margin-left:130px;margin-top:4px;" ></span>
					<img id="updateProgress" src="/images/quotabar.gif" height="20px;" style="width:0%">
					
				</div>
			</div>
		</div>
		<img style="margin-top:5px;margin-left:9px; *margin-top:-10px; width:283px;" src="/images/New_ui/networkmap/linetwo2.png">
		<div class="font_style" style="margin-left:10px;margin-bottom:5px;margin-top:10px;">Detail information</div>
		<div >
			<table border="0" width="98%" align="center" height="100px;"><tr>
				<td style="vertical-align:top" height="100px;">
					<span id="log_field" >
						<textarea cols="15" rows="13" readonly="readonly" id="textarea_disk0" style="resize:none;display:none;width:98%; font-family:'Courier New', Courier, mono; font-size:11px;background:#475A5F;color:#FFFFFF;"></textarea>
						<textarea cols="15" rows="13" readonly="readonly" id="textarea_disk1" style="resize:none;display:none;width:98%; font-family:'Courier New', Courier, mono; font-size:11px;background:#475A5F;color:#FFFFFF;"></textarea>
					</span>
				</td>
			</tr></table>
		</div>
		<div style="margin-top:20px;margin-bottom:10px;"align="center">
			<input id="btn_scan" type="button" class="button_gen" onclick="go_scan();" value="Scan" >
			<input id="btn_abort" type="button" class="button_gen" onclick="abort_scan();" value="Abort" style="display:none">
			<img id="loadingIcon" style="display:none;margin-right:10px;" src="/images/InternetScan.gif">
		</div>
    </td>
  </tr>

  <tr>
    <td style="background-color:#4D595D;" >
		<div class="font_style" style="margin-left:12px;margin-top:10px;">Schedule scan setting</div>
		<img style="margin-top:5px;margin-left:10px; *margin-top:-5px;" src="/images/New_ui/networkmap/linetwo2.png">
			<div style="margin-left:10px;">
				<table>
					<tr class="font_style">
						<td style="width:100px;">
							<div style="margin-bottom:5px;" >Frenqucy</div>
							<select name="diskmon_freq" onchange="freq_change();" class="input_option">
								<option value="0" <% nvram_match("diskmon_freq", "0", "selected"); %>>Disable</option>
								<option value="1" <% nvram_match("diskmon_freq", "1", "selected"); %>>Monthly</option>
								<option value="2" <% nvram_match("diskmon_freq", "2", "selected"); %>>Weekly</option>
								<option value="3" <% nvram_match("diskmon_freq", "3", "selected"); %>>Daily</option>							
							</select>
						</td>							
						<td >
							<div id="date_field">
								<div style="margin-bottom:5px;">Date</div>
								<select name="freq_mon" class="input_option" onchange="freq_change();">
									<option value="1">1</option>
									<option value="2">2</option>
									<option value="3">3</option>
									<option value="4">4</option>
									<option value="5">5</option>
									<option value="6">6</option>
									<option value="7">7</option>
									<option value="8">8</option>
									<option value="9">9</option>
									<option value="10">10</option>
									<option value="11">11</option>
									<option value="12">12</option>
									<option value="13">13</option>
									<option value="14">14</option>
									<option value="15">15</option>
									<option value="16">16</option>
									<option value="17">17</option>
									<option value="18">18</option>
									<option value="19">19</option>
									<option value="20">20</option>
									<option value="21">21</option>
									<option value="22">22</option>
									<option value="23">23</option>
									<option value="24">24</option>
									<option value="25">25</option>
									<option value="26">26</option>
									<option value="27">27</option>
									<option value="28">28</option>
									<option value="29">29</option>
									<option value="30">30</option>
									<option value="31">31</option>
								</select>
							</div>
						</td>
						<td>
							<div id="week_field">
								<div style="margin-bottom:5px">Week</div>
								<select name="freq_week" class="input_option" onchange="freq_change();">
									<option value="0">Sun</option>
									<option value="1">Mon</option>
									<option value="2">Tue</option>
									<option value="3">Wed</option>
									<option value="4">Thu</option>
									<option value="5">Fri</option>
									<option value="6">Sat</option>
								</select>
							</div>
						</td>
						<td>
							<div id="time_field">
								<div style="margin-bottom:5px;">Time</div>
								<select name="freq_hour" class="input_option" onchange="freq_change();">
									<option value="0">0</option>
									<option value="1">1</option>
									<option value="2">2</option>
									<option value="3">3</option>
									<option value="4">4</option>
									<option value="5">5</option>
									<option value="6">6</option>
									<option value="7">7</option>
									<option value="8">8</option>
									<option value="9">9</option>
									<option value="10">10</option>
									<option value="11">11</option>
									<option value="12">12</option>
									<option value="13">13</option>
									<option value="14">14</option>
									<option value="15">15</option>
									<option value="16">16</option>
									<option value="17">17</option>
									<option value="18">18</option>
									<option value="19">19</option>
									<option value="20">20</option>
									<option value="21">21</option>
									<option value="22">22</option>
									<option value="23">23</option>
								</select>
							</div>
						</td>
					</tr>
				</table>
			</div>
				<img style="margin-top:5px;margin-left:10px; *margin-top:-10px;" src="/images/New_ui/networkmap/linetwo2.png">
				<div id="schedule_desc">
					<div  class="font_style" style="margin-top:5px;margin-left:13px;margin-right:10px;" >
						You just scheduled to do disk scan at 
						<span id="schedule_time" style="display:none;font-weight:bolder;"></span>&nbsp
						on<span id="schedule_week" style="display:none;font-weight:bolder;"></span>
						<span id="schedule_date" style="display:none;font-weight:bolder;"></span>&nbsp
						<span id="schedule_frequency" style="display:none;font-weight:bolder;"></span>									
					</div>
					<div class="font_style" style="margin-top:5px;margin-left:13px;margin-right:10px;">
						During scanning process, all disk activies be stopped.
					</div>
				</div>
			<div style="margin-top:20px;margin-bottom:10px;" align="center">
				<input type="button" class="button_gen" onclick="apply_schedule();" value="<#CTL_apply#>">
				<img id="loadingIcon_apply" style="display:none;margin-right:10px;" src="/images/InternetScan.gif">
			</div>
    </td>
  </tr>
 
</table>
</form>
</body>
</html>
