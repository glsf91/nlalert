import QtQuick 2.1
import qb.components 1.0


Screen {
	id: nlalertScreen
	screenTitle: "NL-Alerts van de afgelopen 7 dagen"

	property alias nlAlertListModel: nlAlertModel

	// loading indicator
	property bool nlalertLoaded: false

	// Function (triggerd by a signal) updates the nlalert list model and the header text
	function updateNlalertList() {
		console.log("********* NLAlert updateNlalertList");
		
		if (!app.nlalertDataRead) {
			noAlertsText.visible = true;
			noAlertsText.text = "NL-Alert berichten ophalen mislukt. Geen internet verbinding?";
		} else {
			 if (nlAlertModel.count > 0) {
				// Update the nlalert list model
				noAlertsText.visible = false;
				fillScreenModel();
				nlalertSimpleList.initialView();
			} else {
				noAlertsText.visible = true;
				if (app.nlalertFilterEnabled) {
					noAlertsText.text = "Geen meldingen - filter aan.";
				} else {
					noAlertsText.text = "Geen meldingen";
				}
			}
		}
		nlalertLoaded = true;

		// Update the header text
		headerText.text = getHeaderText();
		buttonsEnabled(true);
	}

	// Function (triggerd by a signal) updates the header text
	function updateNlalertFilter() {
		headerText.text = getHeaderText();
		filterButton.selected = app.nlalertFilterEnabled;
		updateNlalertList();
	}

	// Function creates the header text using the correct XML nodes
	function getHeaderText() {
		var str = "";
		if(!app.nlalertDataRead) return str;

		if (app.nlalertFilterEnabled) {
			str += "NL-Alert (regio): ";
		} else {
			str += "NL-Alert (alles): ";
		}
		
		if (nlAlertModelScreen.count == 1) {
			str += nlAlertModelScreen.count + " melding";
		} else {
			str += nlAlertModelScreen.count + " meldingen";
		}
		return str;
	}


	function buttonsEnabled(enabled) {
		if (enabled) {
//			refreshButton.state = 'up'
			filterButton.state = app.nlalertFilterEnabled ? 'selected' : 'up';
		} else {
//			refreshButton.state = 'disabled';
			filterButton.state = 'disabled';
		}
	}

	function refreshButtonEnabled(enabled) {
		refreshButton.enabled = enabled;
	}


	anchors.fill: parent

	Component.onCompleted: {
		app.nlalertUpdated.connect(updateNlalertList)
		app.nlalertFilterUpdated.connect(updateNlalertFilter)
	}

	onShown: {
		console.log("********* NLAlert NlalertScreen onShown");
		buttonsEnabled(false);
		// Initialize new NL-Alert data request and clear the list model view
		updateNlalertFilter();
		addCustomTopRightButton("Instellingen");
	}

	onCustomButtonClicked: {
		if (app.nlalertConfigurationScreen) app.nlalertConfigurationScreen.show();
	}

	// Fill model used for screen from listmodel
    function fillScreenModel() {

        nlAlertModelScreen.clear();

        for (var n=0; n < nlAlertListModel.count; n++) {
			// Update if not filtered or filtered and in range of regio distance
			if (!app.nlalertFilterEnabled || 
			    (app.nlalertFilterEnabled && (nlAlertListModel.get(n).distance < app.nlalertRegioRange)) ) {
			
				nlAlertModelScreen.append({ alertTime : nlAlertListModel.get(n).alertTime,
                                     latitude : nlAlertListModel.get(n).latitude,
                                     longitude : nlAlertListModel.get(n).longitude,
                                     alertLocation : nlAlertListModel.get(n).alertLocation,
                                     description : nlAlertListModel.get(n).description,
                                     distance : nlAlertListModel.get(n).distance});
			}
        }
		
		console.log("********* NLAlert fillScreenModel count: " + nlAlertModelScreen.count);
    }

	// Is there an empty alertLocation in the listmodel?
    function emptyAlertLocationInNlAlertModel() {
        for (var n=0; n < nlAlertListModel.count; n++) {
            if (nlAlertListModel.get(n).alertLocation.length == 0 ) {
                console.log("********* NLAlert emptyAlertLocationInNlAlertModel: True" );
                return true;
            }
        }

        console.log("********* NLAlert emptyAlertLocationInNlAlertModel: False" );
        return false;
    }

	Item {
		id: header
		height: isNxt ? 55 : 45
		anchors.horizontalCenter: parent.horizontalCenter
		width: isNxt ? parent.width - 95 : parent.width - 76

		Text {
			id: headerText
			text: getHeaderText()
			font.family: qfont.semiBold.name
			font.pixelSize: isNxt ? 25 : 20
			anchors {
				left: header.left
				bottom: parent.bottom
			}
		}

		StandardButton {
			id: filterButton
			text: "Filter"

			anchors {
				right: refreshButton.left
				rightMargin: 5
				bottom: parent.bottom
			}

			rightClickMargin: 2
			bottomClickMargin: 5

			selected: false

			onClicked: {
				if (app.nlalertFilterEnabled) {
					app.nlalertFilterEnabled = false
					fillScreenModel();
				}
				else {
					app.nlalertFilterEnabled = true;
					fillScreenModel();
				}
				updateNlalertFilter();
				app.saveSettings();
			}
		}

		IconButton {
			id: refreshButton
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			leftClickMargin: 3
			bottomClickMargin: 5
			iconSource: "qrc:/tsc/refresh.svg"
			onClicked: {
				// Get new NL-alert data
			   refreshButton.enabled = false;
			   app.readReverseGEOCache();
			   app.refreshNLAlertData();
			   setEnableRefreshButtonTimer.start();
			}
		}
	}

	Rectangle {
		id: content
		anchors.horizontalCenter: parent.horizontalCenter
		width: isNxt ? parent.width - 95 : parent.width - 76
		height: isNxt ? parent.height - 94 : parent.height - 75
		y: isNxt ? 64 : 51
		radius: 3

		NlalertSimpleList {
			id: nlalertSimpleList
			delegate: NlalertDelegate{}
			dataModel: nlAlertModelScreen
			itemHeight: isNxt ? 91 : 73
			itemsPerPage: 4
			anchors.top: parent.top
			downIcon: "qrc:/tsc/arrowScrolldown.png"
			buttonsHeight: isNxt ? 180 : 144
			buttonsVisible: true
			scrollbarVisible: true
		}

		Throbber {
			id: refreshThrobber
			anchors.centerIn: parent
			visible: !nlalertLoaded
		}

		Text {
			id: noAlertsText
			visible: false
			anchors.centerIn: parent
			font.family: qfont.italic.name
			font.pixelSize: isNxt ? 18 : 15
		}
	}

	Text {
		id: footer
		text: "Laatste gelukte update van: " + ((app.nlalertLastUpdateTime.length == 0 ) ? "N/A" : app.nlalertLastUpdateTime) + ". Verversing elke " + app.nlalertRefreshIntervalMinutes + " minuten. Laatste responscode: " + app.nlalartLastResponseStatus
		anchors {
			baseline: parent.bottom
			baselineOffset: -5
			right: parent.right
			rightMargin: 15
		}
		font {
			pixelSize: isNxt ? 18 : 15
			family: qfont.italic.name
		}
	}

    ListModel {
            id: nlAlertModelScreen
    }

    ListModel {
            id: nlAlertModel
    }


	// Timer for enable refresh button after 1 minute because of rate limit NL-Alert
    Timer {
        id: setEnableRefreshButtonTimer
        interval: 60000  
        triggeredOnStart: false
        running: false
        repeat: false
        onTriggered: {
            console.log("********* NLAlert setEnableRefreshButtonTimer start");
            refreshButton.enabled = true;
        }

    }


}
