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
    property int nlalertRegioRange    : 0
    property int nlalertShowTileAlertsDurationHours : 0
    property bool enableSystray : false

    property variant nlAlertData
    property variant geoData
    property variant geoReverseDataCache

	// for Tile
    property int nlalertInsideAreaAlerts  : 0
    property int nlalertOutsideAreaAlerts : 0
    property int nlalertRegioAlerts       : 0
	property bool nlalertIconShow : false
    property string tileStatus : "Wachten op data....."

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
	property int nlalertRefreshIntervalMinutes : 15;
	
	// used for max short retries
	property int nlalertRetry : 0

	// remember last notification for which message id 
	property string lastNotifyId : ""

	property bool debugOutput : false						// Show console messages. Turn on in settings file !

    property bool debug : false


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
		id: nlalertGEOCacheFile
		source: "file:///tmp/nlalert.geoLocations.json"
 	}

	FileIO {
		id: nlalertResponseFile
		source: "file:///tmp/nlalert-response.json"
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
			nlalertRegioRange = nlalertSettingsJson['RegioRange'];		
			nlalertShowTileAlertsDurationHours = nlalertSettingsJson['Duration'];	

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
		

 		var tmpUserSettingsJson = {
			"Latitude"      : nlalertownLatitude,
			"Longitude"     : nlalertownLongitude,
			"RegioRange"    : nlalertRegioRange,
			"Duration"      : nlalertShowTileAlertsDurationHours,
 			"TrayIcon"      : tmpTrayIcon,
			"filterEnabled" : tmpFilterEnabled,
			"DebugOn"		: tmpDebugOn
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

		// just for debugging an reading NL-Alert data from file
        if (debug) {
			nlalertDataRead = true;
            readNLAlertResponse();  // debug
            if (debugOutput) console.log("********* NLAlert refreshNL-AlertData debug on");
			tileStatus = "Debug aan.....";
            return;
        }

        var xmlhttp = new XMLHttpRequest();
        xmlhttp.open("GET", "https://app.nl-alert.nl/api/v1/timeline/7/alerts", true);
		xmlhttp.setRequestHeader("User-Agent", "okhttp/3.12.1");
		
        xmlhttp.onreadystatechange = function() {
            if (debugOutput) console.log("********* NLAlert refreshNL-AlertData readyState: " + xmlhttp.readyState );
            if (xmlhttp.readyState == XMLHttpRequest.DONE) {
				if (debugOutput) console.log("********* NLAlert refreshNL-AlertData http status: " + xmlhttp.status);

				nlalartLastResponseStatus = xmlhttp.status;
				nlalertDataRead = true;

//				if (debugOutput) console.log("********* NLAlert refreshNL-AlertData NL-Alert headers received: " + xmlhttp.getAllResponseHeaders());
//				if (debugOutput) console.log("********* NLAlert refreshNL-AlertData NL-Alert data received: " + xmlhttp.responseText);

				// save headers
				var doc1 = new XMLHttpRequest();
				doc1.open("PUT", "file:///tmp/nlalert-response-headers.json");
				doc1.send(xmlhttp.getAllResponseHeaders());

				// save response
				var doc2 = new XMLHttpRequest();
				doc2.open("PUT", "file:///tmp/nlalert-response.json");
				doc2.send(xmlhttp.responseText);

				if (xmlhttp.status == 200) {
					nlalertRetry = 0;
					nlalertScreen.refreshButtonEnabled(true);  // Allow manual refresh
					
					nlAlertData = JSON.parse(xmlhttp.responseText);

					tileStatus = "Verwerken gegevens.....";
					processNlAlertData();
				} else {
					tileStatus = "Ophalen gegevens mislukt.....";
					if (xmlhttp.status == 429) {  //  Too Many Requests
						nlalertScreen.refreshButtonEnabled(false);  // Don't allow manual refresh
						var retryAfter = xmlhttp.getResponseHeader("retry-after");
						if (debugOutput) console.log("********* NLAlert refreshNL-AlertData NL-Alert header retry-after: " + retryAfter);
						if ( retryAfter <= 2) { 
							retryAfter = 3;
						}
						if (nlalertRetry < 3) {  // max 3 retries in short time
							nlalertTimer.stop();
							nlalertTimer.interval = (retryAfter * 1000) + 500;
							nlalertTimer.start();
							nlalertRetry = nlalertRetry +1;
							if (debugOutput) console.log("********* NLAlert refreshNL-AlertData schedule retry: " + nlalertRetry + " at " + (new Date().toLocaleString('nl-NL')) );
							tileStatus = "Mislukt, start poging " + nlalertRetry + ".....";
						} else {
							if (debugOutput) console.log("********* NLAlert refreshNL-AlertData Too much retries. Wait for regular refresh");
							nlalertScreen.refreshButtonEnabled(true);  // Allow manual refresh
						}
					}
				}
			}
        }
        xmlhttp.send();
    }


	// Popup an alarm when NL-Alert in area range received and not yet notified
	function notifyUser() {
		var n;
		if (debugOutput) console.log("********* NLAlert notifyUser");
		
		// Only get the first NL-Alert message in the area or regio range
        for (n=0; n < nlalertScreen.nlAlertListModel.count; n++) {
            if (nlalertScreen.nlAlertListModel.get(n).regio || nlalertScreen.nlAlertListModel.get(n).inArea) {
				if (debugOutput) console.log("********* NLAlert notifyUser regio or area message found:" +  nlalertScreen.nlAlertListModel.get(n).alertId);
				break;
			}
		}
		
		// if there is a message in the regio or area range and not alarm already done
		if (n < nlalertScreen.nlAlertListModel.count) {
			if ( nlalertScreen.nlAlertListModel.get(n).alertId != lastNotifyId ) {
				screenStateController.wakeup();
				
				if (nlalertScreen.nlAlertListModel.get(n).regio) {
					alarmPopup.regio = true;
					alarmPopup.messageText = nlalertScreen.nlAlertListModel.get(n).alertTime + 
											 " " + nlalertScreen.nlAlertListModel.get(n).alertLocation + 
											 " " + nlalertScreen.nlAlertListModel.get(n).distance + " km\n" + 
											 nlalertScreen.nlAlertListModel.get(n).description;

				} else {
					alarmPopup.regio = false;
					alarmPopup.messageText = nlalertScreen.nlAlertListModel.get(n).alertTime + 
											 " " + nlalertScreen.nlAlertListModel.get(n).alertLocation + 
											 "\n" + nlalertScreen.nlAlertListModel.get(n).description;
				}
				
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

    function processNlAlertData(){
		var distance;
		var timediff;
		var nlalertDate;
		var inArea;
		
		var now = new Date();
		nlalertLastUpdateTime = now.toLocaleString('nl-NL'); 

		// Count for Tile
		nlalertInsideAreaAlerts = 0;
		nlalertRegioAlerts = 0;
		nlalertOutsideAreaAlerts = 0;
		nlalertIconShow = false;

		try {  // in case empty JSON
			for (var i = 0; i < nlAlertData['data'].length; i++) {
				var regioRange = false;
				var id = nlAlertData['data'][i]['id'];
				var time = nlAlertData['data'][i]['time'];
				var status = nlAlertData['data'][i]['status'];
				var description = nlAlertData['data'][i]['description'];
				var areaCenter = nlAlertData['data'][i]['areaCenter'];
				var area = nlAlertData['data'][i]['area'];

				if (debugOutput) console.log("********* NLAlert processNlAlertData id: " + id );
				if (debugOutput) console.log("********* NLAlert processNlAlertData time: " + time );
				if (debugOutput) console.log("********* NLAlert processNlAlertData status: " + status );
				if (debugOutput) console.log("********* NLAlert processNlAlertData description: " + description );
				if (debugOutput) console.log("********* NLAlert processNlAlertData areaCenter.latitude: " + areaCenter.latitude );
				if (debugOutput) console.log("********* NLAlert processNlAlertData areaCenter.longitude: " + areaCenter.longitude );
				if (debugOutput) console.log("********* NLAlert processNlAlertData area len: " + area.length );

				nlalertDate = new Date(time);
				timediff = getHoursBetweenDates(now,nlalertDate);
//				if (debugOutput) console.log("********* NLAlert processNlAlertData difference time in hours: " + timediff );

				distance = Math.round(haversineDistance(areaCenter.latitude,areaCenter.longitude,nlalertownLatitude,nlalertownLongitude));

				inArea = locationInArea(area,nlalertownLongitude,nlalertownLatitude);
				if (inArea) {
					if (debugOutput) console.log("********* NLAlert processNlAlertData Alert in Area");
					distance = 0;
				} else {
					if (debugOutput) console.log("********* NLAlert processNlAlertData Alert NOT in Area");
				}

				// Count alerts in alert area and show icon
				if ( inArea && (timediff <= nlalertShowTileAlertsDurationHours || nlalertShowTileAlertsDurationHours == 0 )) {
					nlalertInsideAreaAlerts = nlalertInsideAreaAlerts + 1;
					nlalertIconShow = true;
				} else 	{  
					// count outside area
					if ( timediff <= nlalertShowTileAlertsDurationHours || nlalertShowTileAlertsDurationHours == 0  ) {
						nlalertOutsideAreaAlerts = nlalertOutsideAreaAlerts + 1;
					}
					// Count alerts in regio range
					if ( distance <= nlalertRegioRange && (timediff <= nlalertShowTileAlertsDurationHours || nlalertShowTileAlertsDurationHours == 0 ) ) {
						// Count alerts in regio range 
						nlalertRegioAlerts = nlalertRegioAlerts + 1;
						regioRange = true;
					}
				}
				
				nlalertScreen.nlAlertListModel.append({ alertId: id,
									 alertTime: time,
									 latitude: areaCenter.latitude,
									 longitude : areaCenter.longitude,
									 alertLocation: "",
									 description: description,
									 distance: distance,
									 regio: regioRange,
									 inArea: inArea});
			}
		} catch(e) {
			if (debugOutput) console.log("********* NLAlert processNlAlertData catch: " + e );
		}

//		if (debugOutput) console.log("********* NLAlert processNlAlertData count in model: " + nlalertScreen.nlAlertListModel.count );

        if (nlalertScreen.nlAlertListModel.count > 0) {
            processReverseGEOCache();
            if (nlalertScreen.emptyAlertLocationInNlAlertModel()) {
                getAllReverseGEO();
            } else {
				tileStatus = "Gereed";
				nlalertUpdated();
				notifyUser();
            }
        } else {
			// no NL-Alerts received
			nlalertUpdated();

			tileStatus = "Gereed";
		}

    }

	// Get reverse GEO for coordinates
    function getReverseGEO(index) {
        if (debugOutput) console.log("********* NLAlert getReverseGEO started voor index:" + index);

        tileStatus = "Ophalen GEO gegevens.....";

        var latitude = nlalertScreen.nlAlertListModel.get(index).latitude;
        var longitude = nlalertScreen.nlAlertListModel.get(index).longitude;
        var alertLocation = "";


        var xmlhttp = new XMLHttpRequest();
		// Needs emailadress and must be unique for every Toon because of policy with rate limit
        var url = "https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=" + latitude + "&lon=" + longitude +
                    "&email=" + nlalertHostname + "@gmail.com" + "&accept-language=nl-NL";
        if (debugOutput) console.log("********* NLAlert getReverseGEO url " + url );

        xmlhttp.open("GET", url, true);
        xmlhttp.onreadystatechange = function() {
            if (debugOutput) console.log("********* NLAlert getReverseGEO readyState: " + xmlhttp.readyState + " http status: " + xmlhttp.status);
            if (xmlhttp.readyState == XMLHttpRequest.DONE ) {
				if (xmlhttp.status == 200) {
					if (debugOutput) console.log("********* NLAlert getReverseGEO response " + xmlhttp.responseText );

					geoData = JSON.parse(xmlhttp.responseText);

					alertLocation = ((geoData.address.state) ? geoData.address.state : "") + " " +
						   ((geoData.address.town) ? geoData.address.town : "") +
						   ((geoData.address.city) ? geoData.address.city : "") + " " +
						   ((geoData.address.suburb) ? geoData.address.suburb : "") + " " +
						   ((geoData.address.road) ? geoData.address.road : "");

					if (debugOutput) console.log("********* NLAlert getReverseGEO alertLocation:" + alertLocation );
					nlalertScreen.nlAlertListModel.set(index, {"alertLocation": alertLocation});

					// If there are more alerts with same location, copy alertLocation
					for (var n=0; n < nlalertScreen.nlAlertListModel.count; n++) {
						if (nlalertScreen.nlAlertListModel.get(n).latitude == latitude && nlalertScreen.nlAlertListModel.get(n).longitude == longitude && nlalertScreen.nlAlertListModel.get(n).alertLocation.length == 0 ) {
							nlalertScreen.nlAlertListModel.set(n, {"alertLocation": alertLocation});
						}
					}

					// process next one after a few seconds
					getReverseGEOTimer.start();
				} else {
					nlalertScreen.nlAlertListModel.set(index, {"alertLocation": "N/A"});
					if (debugOutput) console.log("********* NLAlert getReverseGEO fout opgetreden bij ophalen alertLocation voor index: " + index );
					// process next one after a few seconds
					getReverseGEOTimer.start();
				}
			}
        }
        xmlhttp.send();
    }

	// Use GEO cache as much as possible
    function processReverseGEOCache() {
        if (debugOutput) console.log("********* NLAlert processReverseGEOCache" );

        if (geoReverseDataCache.length == 0) {    // cache empty ?
			if (debugOutput) console.log("********* NLAlert processReverseGEOCache cache empty" );
            return;
        }

        for (var  n=0; n < nlalertScreen.nlAlertListModel.count; n++) {
            if (nlalertScreen.nlAlertListModel.get(n).alertLocation.length == 0 ) {
                for (var i = 0; i < geoReverseDataCache['locations'].length; i++) {
                    if (nlalertScreen.nlAlertListModel.get(n).latitude == geoReverseDataCache['locations'][i]['latitude'] &&
                            nlalertScreen.nlAlertListModel.get(n).longitude == geoReverseDataCache['locations'][i]['longitude'] &&
                            nlalertScreen.nlAlertListModel.get(n).alertLocation.length == 0 ) {
                        nlalertScreen.nlAlertListModel.set(n, {"alertLocation": geoReverseDataCache['locations'][i]['alertLocation']});
						if (debugOutput) console.log("********* NLAlert processReverseGEOCache found in cache alertLocation: " + geoReverseDataCache['locations'][i]['alertLocation']);
                    }
                }
            }
        }

    }

    function getAllReverseGEO() {
        if (debugOutput) console.log("********* NLAlert getAllReverseGEO" );
        var n;
		var errorOccured = false;

		// Process all locations
        for (n=0; n < nlalertScreen.nlAlertListModel.count; n++) {
            if (nlalertScreen.nlAlertListModel.get(n).alertLocation.length == 0 ) {
                break;
            }
			if (nlalertScreen.nlAlertListModel.get(n).alertLocation == "N/A") {
				errorOccured = true;
			}
        }

		// If not all locations are processed then reverse GEO request one location
        if (n < nlalertScreen.nlAlertListModel.count) {
            getReverseGEO(n);
        } else {
			// If all processed
			if (!errorOccured) {
				saveReverseGEOCache();
			}
	        tileStatus = "Gereed";
			nlalertUpdated();
        }
    }

	// Save locations to cache for next time
    function saveReverseGEOCache(){
        var tmpGEO = { locations: [] };

        for (var n=0; n < nlalertScreen.nlAlertListModel.count; n++) {

            tmpGEO.locations.push({
                "alertLocation" : nlalertScreen.nlAlertListModel.get(n).alertLocation,
                "latitude"  : nlalertScreen.nlAlertListModel.get(n).latitude,
                "longitude"       : nlalertScreen.nlAlertListModel.get(n).longitude
            });
        }

        var doc = new XMLHttpRequest();
        doc.open("PUT", "file:///tmp/nlalert.geoLocations.json");
        doc.send(JSON.stringify(tmpGEO));
    }

	// Read locations from cache
    function readReverseGEOCache(){
        geoReverseDataCache = "";

		try {
			geoReverseDataCache = JSON.parse(nlalertGEOCacheFile.read());
			
			if (geoReverseDataCache['locations'].length > 0) {
				if (debugOutput) console.log("********* NLAlert readReverseGEOCache file data found");
			}
		} catch(e) {
		}
    }

    function readNLAlertResponse(){   // only debug

		try {
			nlAlertData = JSON.parse(nlalertResponseFile.read());
			
		} catch(e) {
		}

		if (nlAlertData['data'].length > 0) {
			if (debugOutput) console.log("********* NLAlert readNLAlertResponse file data found");
			processNlAlertData();
		}
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

	// Timer for read reverse GEO location one by one an not to fast because of policy rate limit
    Timer {
        id: getReverseGEOTimer
        interval: 3000  // 3 seconds because of policy nominatim.openstreetmap.org (max 1 per second)
        triggeredOnStart: false
        running: false
        repeat: false
        onTriggered: {
            if (debugOutput) console.log("********* NLAlert getReverseGEOTimer start");
            getAllReverseGEO();
        }

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
			readReverseGEOCache();
			refreshNLAlertData();		
		}
	}
	
}
