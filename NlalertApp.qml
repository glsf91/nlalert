import QtQuick 2.1
import qb.components 1.0
import qb.base 1.0
import FileIO 1.0

App {
	id: nlalertApp

	property url tileUrl : "NlalertTile.qml"
	property url thumbnailIcon: "qrc:/tsc/nlalertSmallNoBG.png"
	
	property url nlalertScreenUrl : "NlalertScreen.qml"
	property url nlalertConfigurationScreenUrl : "NlalertConfigurationScreen.qml"
	property url trayUrl : "NlalertTray.qml"
	property url alarmPopupUrl: "NlalertAlarmPopup.qml"

	property NlalertConfigurationScreen nlalertConfigurationScreen
	property NlalertScreen nlalertScreen
	property Popup alarmPopup

	// settings
    property real nlalertownLatitude  : 51.00
    property real nlalertownLongitude : 5.6
    property int nlalertShowTileAlertsDurationHours : 0
    property bool enableSystray : false

    property variant nlAlertData

	// for Tile
    property int nlalertInsideAreaAlerts  : 0
    property int nlalertOutsideAreaAlerts : 0
	property bool nlalertIconShow : false
    property string tileStatus : "Wachten op data....."

	property int daysNLalertData : 7

	// true when data is read
	property bool nlalertDataRead : false

	// filter on when true
	property bool nlalertFilterEnabled : false

	// need unique id for reverse GEO requests
	property string nlalertHostname

	property string nlalertLastUpdateTime
	property string nlalartLastResponseStatus : "N/A"
	
	// user settings from config file
	property variant nlalertSettingsJson 

	// Refresh interval in minutes
	property int nlalertRefreshIntervalMinutes : 10;
	
	// remember last notification for which message id 
	property string lastNotifyId : ""

	property bool debugOutput : false						// Show console messages. Turn on in settings file !

    property bool debugData : false


    property variant results : []


	// Fileinfo signals, used to update the listview and filter enabled button
	signal nlalertUpdated()
	signal nlalertFilterUpdated()


	FileIO {
		id: nlalertHostnameFile
		source: "file:///etc/hostname"
 	}

	FileIO {
		id: nlalertSettingsFile
		source: "file:///mnt/data/tsc/nlalert.userSettings.json"
 	}


	FileIO {
		id: nlalertResponseFile
		source: "file:///tmp/nlalert-response.html"
 	}

	FileIO {
		id: nlalertLastAlarmFile
		source: "file:///mnt/data/tsc/nlalert.last-alarm.json"
 	}

	Component.onCompleted: {
		// read user settings

		try {
			nlalertSettingsJson = JSON.parse(nlalertSettingsFile.read());
			if (nlalertSettingsJson['TrayIcon'] == "Yes") {
				enableSystray = true
			} else {
				enableSystray = false
			}
			nlalertownLatitude = nlalertSettingsJson['Latitude'];		
			nlalertownLongitude = nlalertSettingsJson['Longitude'];		
			nlalertShowTileAlertsDurationHours = nlalertSettingsJson['Duration'];	
			daysNLalertData = nlalertSettingsJson['daysNLalertData'];
			
			if (nlalertSettingsJson['filterEnabled'] == "Yes") {
				nlalertFilterEnabled = true
			} else {
				nlalertFilterEnabled = false
			}		

			nlalertHostname	= nlalertHostnameFile.read();
			if (debugOutput) console.log("********* NLAlert onCompleted hostname: " + nlalertHostname);
			
			if (nlalertSettingsJson['DebugOn'] == "Yes") {
				debugOutput = true
			} else {
				debugOutput = false
			}

			if (nlalertSettingsJson['DebugDataOn'] == "Yes") {
				debugData = true
			} else {
				debugData = false
			}

		} catch(e) {
		}

		readNLAlertLastAlarmId();
		
		nlalertTimer.start();

	}

	function init() {
		registry.registerWidget("tile", tileUrl, this, null, {thumbLabel: "NL-Alert", thumbIcon: thumbnailIcon, thumbCategory: "general", thumbWeight: 30, baseTileWeight: 10, thumbIconVAlignment: "center"});
		registry.registerWidget("screen", nlalertScreenUrl, this, "nlalertScreen");
		registry.registerWidget("screen", nlalertConfigurationScreenUrl, this, "nlalertConfigurationScreen");
		registry.registerWidget("systrayIcon", trayUrl, this, "nlalertTray");
		registry.registerWidget("popup", alarmPopupUrl, this, "alarmPopup");
	}

	function saveSettings() {
		// save user settings
		if (debugOutput) console.log("********* NLAlert saveSettings");

		var tmpTrayIcon = "";
		if (enableSystray == true) {
			tmpTrayIcon = "Yes";
		} else {
			tmpTrayIcon = "No";
		}
		
		var tmpFilterEnabled = "";
		if (nlalertFilterEnabled == true) {
			tmpFilterEnabled = "Yes";
		} else {
			tmpFilterEnabled = "No";
		}

		var tmpDebugOn = "";
		if (debugOutput == true) {
			tmpDebugOn = "Yes";
		} else {
			tmpDebugOn = "No";
		}

		var tmpDebugDataOn = "";
		if (debugData == true) {
			tmpDebugDataOn = "Yes";
		} else {
			tmpDebugDataOn = "No";
		}
		

 		var tmpUserSettingsJson = {
			"Latitude"      	: nlalertownLatitude,
			"Longitude"     	: nlalertownLongitude,
			"Duration"      	: nlalertShowTileAlertsDurationHours,
 			"TrayIcon"      	: tmpTrayIcon,
			"filterEnabled" 	: tmpFilterEnabled,
			"DebugOn"			: tmpDebugOn,
			"DebugDataOn"		: tmpDebugDataOn,
			"daysNLalertData"	: daysNLalertData
		}

  		var doc = new XMLHttpRequest();
   		doc.open("PUT", "file:///mnt/data/tsc/nlalert.userSettings.json");
   		doc.send(JSON.stringify(tmpUserSettingsJson ));
	}

    function toRad(x) {
            return x * Math.PI / 180;
    }

	// Calculate distance in km between 2 locations
    function haversineDistance(lat1, lon1, lat2, lon2) {

        var R = 6371; // km
        var x1 = lat2 - lat1;
        var dLat = toRad(x1);
        var x2 = lon2 - lon1;
        var dLon = toRad(x2);
        var a = Math.sin(dLat / 2) * Math.sin(dLat / 2) + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        var d = R * c;
        return d;
    }

	// Get NL-Alert data
    function refreshNLAlertData() {
        if (debugOutput) console.log("********* NLAlert refreshNL-AlertData started");

		nlalertDataRead = false;
        tileStatus = "Ophalen gegevens.....";
		nlalertScreen.nlAlertListModel.clear();
		results = [];

		// just for debugging an reading NL-Alert data from file
        if (debugData) {
			nlalertDataRead = true;
            if (debugOutput) console.log("********* NLAlert refreshNL-AlertData debug on");
			tileStatus = "Debug aan.....";
			readNLAlertResponse();
			nlalertScreen.refreshButtonEnabled(true);  // Allow manual refresh
            return;
        }

        var xmlhttp = new XMLHttpRequest();
        xmlhttp.open("GET", "https://crisis.nl/nl-alert/nl-alerts/", true);
		
        xmlhttp.onreadystatechange = function() {
            if (debugOutput) console.log("********* NLAlert refreshNL-AlertData readyState: " + xmlhttp.readyState );
            if (xmlhttp.readyState == XMLHttpRequest.DONE) {
				if (debugOutput) console.log("********* NLAlert refreshNL-AlertData http status: " + xmlhttp.status);

				nlalartLastResponseStatus = xmlhttp.status;
				nlalertDataRead = true;

//				if (debugOutput) console.log("********* NLAlert refreshNL-AlertData NL-Alert headers received: " + xmlhttp.getAllResponseHeaders());
//				if (debugOutput) console.log("********* NLAlert refreshNL-AlertData NL-Alert data received: " + xmlhttp.responseText);

				// save response
				var doc2 = new XMLHttpRequest();
				doc2.open("PUT", "file:///tmp/nlalert-response.html");
				doc2.send(xmlhttp.responseText);

				if (xmlhttp.status == 200) {
					nlalertScreen.refreshButtonEnabled(true);  // Allow manual refresh
					tileStatus = "Verwerken gegevens.....";

					processNlAlertData(xmlhttp.responseText);
				} else {
					tileStatus = "Ophalen gegevens mislukt.....";
				}
			}
        }
        xmlhttp.send();
    }


    function processNlAlertData(response){
		if (debugOutput) console.log("********* NLAlert processNlAlertData started");
		
		var inArea;
        var url;
        var alertDate;
        var detailUrl;
        var alertMessage;
        var alertId;
		var timediff;
		var nlalertDate;
		var alertDateTmp;
		
		// Count for Tile
		nlalertInsideAreaAlerts = 0;
		nlalertOutsideAreaAlerts = 0;
		nlalertIconShow = false;

		var now = new Date();
		nlalertLastUpdateTime = now.toLocaleString('nl-NL'); 

		var n1 = response.indexOf('<div class=\"common results\">') + 1;
		var n2 = response.indexOf('<ul class=\"paging\">',n1);
		var allmatches = response.substring(n1, n2);
		var alertArray = allmatches.split('<div class=\"common results\">');
		if (debugOutput) console.log("********* NLAlert processNlAlertData alertArray length: " + alertArray.length);

		for(var alertCount in alertArray){
//            if (debugOutput) console.log("********* NLAlert processNlAlertData alertArray: " + alertCount + " " + alertArray[alertCount])

			n1 = alertArray[alertCount].indexOf('<a href=\"') + 10;
			n2 = alertArray[alertCount].indexOf('\">', n1);
			detailUrl = alertArray[alertCount].substring(n1, n2);

			n1 = alertArray[alertCount].indexOf('<h3>') + 4;
			n2 = alertArray[alertCount].indexOf('</h3>', n1);
			alertDateTmp = alertArray[alertCount].substring(n1, n2);
			alertDate = alertDateTmp.replace(/(<div.*<\/div>)?/,"");

			n1 = alertArray[alertCount].indexOf('<p class=\"results\">') + 19;
			n2 = alertArray[alertCount].indexOf('</p>', n1);
			alertMessage = alertArray[alertCount].substring(n1, n2);

			n1 = detailUrl.indexOf('a=') + 2;
			alertId = detailUrl.substring(n1);

			if (debugOutput) console.log("********* NLAlert processNlAlertData Alert:" + alertCount + " alertId: " + alertId);
			if (debugOutput) console.log("********* NLAlert processNlAlertData Alert:" + alertCount + " alertDate: " + alertDate);
			if (debugOutput) console.log("********* NLAlert processNlAlertData Alert:" + alertCount + " alertMessage: " + alertMessage);
			if (debugOutput) console.log("********* NLAlert processNlAlertData Alert:" + alertCount + " detailUrl: " + detailUrl);


			nlalertDate = new Date(convertDateTime(alertDate));
			timediff = getHoursBetweenDates(now,nlalertDate);
			if (debugOutput) console.log("********* NLAlert processNlAlertData difference time in hours: " + timediff );
			
			// skip recurring messages which are more then 7 days old
			if (timediff > (daysNLalertData*24)) {
				continue;
			}

			results.push({ alertDate: alertDate,
							 detailUrl: detailUrl,
							 alertMessage: alertMessage,
							 alertId: alertId,
							 timediffHours: timediff,
							 processed: false
						 });

		}


		// No data to process
		if (results.length === 0) {
			if (debugOutput) console.log("********* NLAlert processNlAlertData No data");
			processAfterNLAlertDetails();
			return;
		}


		// Get area data
        for(var count in results){
            if (debugOutput) console.log("********* NLAlert processNlAlertData Alert:" + count + " alertId: " + results[count].alertId);
            if (debugOutput) console.log("********* NLAlert processNlAlertData Alert:" + count + " detailUrl: " + results[count].detailUrl);
            if (debugOutput) console.log("********* NLAlert processNlAlertData Alert:" + count + " alertDate: " + results[count].alertDate);
            if (debugOutput) console.log("********* NLAlert processNlAlertData Alert:" + count + " alertMessage: " + results[count].alertMessage);
            if (debugOutput) console.log("********* NLAlert processNlAlertData Alert:" + count + " timediffHours: " + results[count].timediffHours);

            url = "https://crisis.nl/" + results[count].detailUrl;
            getNLAlertDetail(results[count].alertId,url);
        }

    }

    function getNLAlertDetail(alertId, url){
        if (debugOutput) console.log("********* NLAlert getNLAlertDetail started for url: " + url);

        var inArea;
		var area;
		
        var xmlhttp = new XMLHttpRequest();
        xmlhttp.open("GET", url, true);
        xmlhttp.onreadystatechange = function() {
            if (debugOutput) console.log("********* NLAlert getNLAlertDetail readyState" + xmlhttp.readyState );
            if (debugOutput) console.log("********* NLAlert getNLAlertDetail status" + xmlhttp.status);
            if (xmlhttp.readyState === XMLHttpRequest.DONE && xmlhttp.status === 200) {
                var response = xmlhttp.responseText;
//                if (debugOutput) console.log("********* NLAlert getNLAlertDetail response" + response );

                if (debugOutput) console.log("********* NLAlert getNLAlertDetail alertId: " + alertId);

                var encodedCode  = xmlhttp.responseText.match(/googlemaps.*staticmap.*enc:(.*)&key/)[1];
//                if (debugOutput) console.log("********* NLAlert getNLAlertDetail encodedCode: " + encodedCode);
                var code = decodeURIComponent(encodedCode);
//                if (debugOutput) console.log("********* NLAlert getNLAlertDetail code: " + code);

                for(var count = 0; count < results.length; count++){
                    if (results[count].alertId === alertId ) {
//                        results[count].code = code;
                        area = decodeCode(code,5);
//                        if (debugOutput) console.log("********* NLAlert getNLAlertDetail area: " + JSON.stringify(area));
//                        if (debugOutput) console.log("********* NLAlert getNLAlertDetail area lat: " + area[0]['latitude']);
//                        if (debugOutput) console.log("********* NLAlert getNLAlertDetail area lon: " + area[0]['longitude']);
                        if (debugOutput) console.log("********* NLAlert getNLAlertDetail area length: " + area.length);

                        inArea = locationInArea(area,nlalertownLongitude,nlalertownLatitude);
                        if (inArea) {
                            if (debugOutput) console.log("********* NLAlert getNLAlertDetail Alert in Area");
                        } else {
                            if (debugOutput) console.log("********* NLAlert getNLAlertDetail Alert NOT in Area");
                        }

						// Count alerts in alert area and show icon
						if ( inArea && (results[count].timediffHours <= nlalertShowTileAlertsDurationHours || nlalertShowTileAlertsDurationHours == 0 )) {
							nlalertInsideAreaAlerts = nlalertInsideAreaAlerts + 1;
//							nlalertIconShow = true;
						} else 	{  
							// count outside area
							if ( results[count].timediffHours <= nlalertShowTileAlertsDurationHours || nlalertShowTileAlertsDurationHours == 0  ) {
								nlalertOutsideAreaAlerts = nlalertOutsideAreaAlerts + 1;
							}
							
						}

                        nlalertScreen.nlAlertListModel.append({alertId: results[count].alertId,
																 alertTime: results[count].alertDate,
																 description: results[count].alertMessage.substring(0,400),
																 inArea: inArea});

						results[count].processed = true;
						
                        break;
                    }
                }
				if (debugOutput) console.log("********* NLAlert getNLAlertDetail count at end: " + count + " for length results: " + results.length);
				
				// if the last one is processed
				if (allResultsProcessed()) {
					if (debugOutput) console.log("********* NLAlert getNLAlertDetail all results are processed");
					processAfterNLAlertDetails();
				}

            }
        }
        xmlhttp.send();
    }

	function processAfterNLAlertDetails(){
		if (debugOutput) console.log("********* NLAlert processAfterNLAlertDetails started");
		
//		if (debugOutput) console.log("********* NLAlert processAfterNLAlertDetails count in model: " + nlalertScreen.nlAlertListModel.count );

        if (nlalertScreen.nlAlertListModel.count > 0) {
			tileStatus = "Gereed";
			nlalertUpdated();
			notifyUser();
        } else {
			// no NL-Alerts received
			nlalertUpdated();

			tileStatus = "Gereed";
		}
	}

	function allResultsProcessed () {
		for (var count in results) {
			if (results[count].processed === false) return false;
		}
		return true;
	}

    function decodeCode (str, precision) {
        var index = 0,
            lat = 0,
            lng = 0,
            coordinates = [],
            shift = 0,
            result = 0,
            bite = null,
            latitude_change,
            longitude_change,
            factor = Math.pow(10, precision || 6);

        // Coordinates have variable length when encoded, so just keep
        // track of whether we've hit the end of the string. In each
        // loop iteration, a single coordinate is decoded.
        while (index < str.length) {

            // Reset shift, result, and byte
            bite = null;
            shift = 0;
            result = 0;

            do {
                bite = str.charCodeAt(index++) - 63;
                result |= (bite & 0x1f) << shift;
                shift += 5;
            } while (bite >= 0x20);

            latitude_change = ((result & 1) ? ~(result >> 1) : (result >> 1));

            shift = result = 0;

            do {
                bite = str.charCodeAt(index++) - 63;
                result |= (bite & 0x1f) << shift;
                shift += 5;
            } while (bite >= 0x20);

            longitude_change = ((result & 1) ? ~(result >> 1) : (result >> 1));

            lat += latitude_change;
            lng += longitude_change;

//            coordinates.push([lat / factor, lng / factor]);
            coordinates.push({latitude: lat / factor,longitude:lng / factor});
        }

        return coordinates;
    }

	// Popup an alarm when NL-Alert in area range received and not yet notified
	function notifyUser() {
		var n;
		if (debugOutput) console.log("********* NLAlert notifyUser");
		
		// Only get the first NL-Alert message in the area or regio range
        for (n=0; n < nlalertScreen.nlAlertListModel.count; n++) {
            if (nlalertScreen.nlAlertListModel.get(n).inArea) {
				if (debugOutput) console.log("********* NLAlert notifyUser area message found:" +  nlalertScreen.nlAlertListModel.get(n).alertId);
				break;
			}
		}
		
		// if there is a message in the regio or area range and not alarm already done
		if (n < nlalertScreen.nlAlertListModel.count) {
			if ( nlalertScreen.nlAlertListModel.get(n).alertId != lastNotifyId ) {
				screenStateController.wakeup();
				
				alarmPopup.messageText = nlalertScreen.nlAlertListModel.get(n).alertTime + 
											 "\n" + nlalertScreen.nlAlertListModel.get(n).description;
				
				if (alarmPopup.visible == false) {
					if (debugOutput) console.log("********* NLAlert notifyUser start alarmPopup" );
					alarmPopup.show();
					stage.openFullscreen(nlalertScreenUrl);
				}
				lastNotifyId = nlalertScreen.nlAlertListModel.get(n).alertId;
				saveNLAlertLastAlarmId(lastNotifyId);
			}
		}
	}

    function convertDateTime(dateTime){

        var parts = dateTime.split(" ");
        var partDate = parts[0].split("-");
        if (partDate[0].length === 1) partDate[0] = '0' + partDate[0];
        if (partDate[1].length === 1) partDate[1] = '0' + partDate[1];

        var resultDate = partDate[2] + "-" + partDate[1] + "-" +partDate[0] + " " + parts[1];
//		if (debugOutput) console.log("********* NLAlert convertDateTime " + dateTime + " to " + resultDate);

        return resultDate;
    }

	function getHoursBetweenDates(endDate, startDate) {
		var diff = endDate.getTime() - startDate.getTime();
		return (diff / (60 * 60 * 1000));
	}

	function isPointInPoly(poly, pt){
		for(var c = false, i = -1, l = poly.length, j = l - 1; ++i < l; j = i)
			((poly[i].y <= pt.y && pt.y < poly[j].y) || (poly[j].y <= pt.y && pt.y < poly[i].y))
			&& (pt.x < (poly[j].x - poly[i].x) * (pt.y - poly[i].y) / (poly[j].y - poly[i].y) + poly[i].x)
			&& (c = !c);
		return c;
	}

	function locationInArea(area,lon,lat){
		if (debugOutput) console.log("********* NLAlert processArea" );
		var points = [];
		var last;

		for (var i = 0; i < area.length; i++) {
			points.push({ x: area[i]['longitude'],
						  y: area[i]['latitude']});
		}
		
		last = points.length - 1;

		// Sometimes no closed polygon in area. Add first point again
		if (points[last].x != area[0]['longitude'] || points[last].y != area[0]['latitude']) {
			points.push({ x: area[0]['longitude'],
						  y: area[0]['latitude']});
		}
		
		return isPointInPoly(points,{x: lon,  y: lat });
	}


    function readNLAlertResponse(){   // only debug
		if (debugOutput) console.log("********* NLAlert readNLAlertResponse");

		try {
			var response = nlalertResponseFile.read();
			
		} catch(e) {
		}

		processNlAlertData(response);
    }


    function readNLAlertLastAlarmId(){   
		try {
			lastNotifyId = nlalertLastAlarmFile.read().trim();
			
		} catch(e) {
			lastNotifyId = "";
		}
		if (debugOutput) console.log("********* NLAlert readNLAlertLastAlarm id: " + lastNotifyId );
    }

    function saveNLAlertLastAlarmId(id){  
		if (debugOutput) console.log("********* NLAlert saveNLAlertLastAlarmId");

		var doc = new XMLHttpRequest();
		doc.open("PUT", "file:///mnt/data/tsc/nlalert.last-alarm.json");
		doc.send(id);
    }

		
	Timer {               // needed for waiting nlalertScreen is loaded an functions can be used and refresh
		id: nlalertTimer
		interval: 10000  // first update after 10 seconds
		triggeredOnStart: false
		running: false
		repeat: true
		onTriggered: {
			if (debugOutput) console.log("********* NLAlert nlalertTimer start " + (new Date().toLocaleString('nl-NL')));
			interval = nlalertRefreshIntervalMinutes * 60 * 1000;  // change interval to x minutes
			refreshNLAlertData();		
		}
	}
	
}

