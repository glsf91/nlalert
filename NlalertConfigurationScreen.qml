import QtQuick 2.1
import qb.components 1.0
import BasicUIControls 1.0;

Screen {
	id: nlalertConfigurationScreen
	screenTitle: "Instellingen NL-Alert app"

	property string qrCodeID

	onShown: {
		addCustomTopRightButton("Opslaan");
		enableSystrayToggle.isSwitchedOn = app.enableSystray;
		lonLabel.inputText = app.nlalertownLongitude;
		latLabel.inputText = app.nlalertownLatitude;
		durationLabel.inputText = app.nlalertShowTileAlertsDurationHours;
		qrCodeID = Math.random().toString(36).substring(7);
		qrCode.content = "https://qutility.nl/geolocation/getlocation.php?id="+qrCodeID;
		qrCodeTimer.running = true;
	}

	onCustomButtonClicked: {
		app.saveSettings();
		qrCodeTimer.running = false;
		hide();
		app.nlalertScreen.refreshData();
	}

        onHidden: {
                qrCodeTimer.running = false;
        }

	function validateCoordinate(text, isFinalString) {
		return null;
	}

	function saveLon(text) {
		//rounding at 4 decimals
		if (text) {
			app.nlalertownLongitude = (Math.round(parseFloat(text.replace(",", ".")) * 10000) / 10000);
			lonLabel.inputText = app.nlalertownLongitude;
	   		app.saveSettings();
		}
	}

	function saveLat(text) {
		//rounding at 4 decimals
		if (text) {
			app.nlalertownLatitude = (Math.round(parseFloat(text.replace(",", ".")) * 10000) / 10000);
			latLabel.inputText = app.nlalertownLatitude;
	   		app.saveSettings();
		}
	}

	function saveDuration(text) {
		if (text) {
			app.nlalertShowTileAlertsDurationHours = parseInt(text);
			durationLabel.inputText = app.nlalertShowTileAlertsDurationHours;
	   		app.saveSettings();
		}
	}
	
	function checkLocation() {
                var xmlhttp = new XMLHttpRequest();
                xmlhttp.onreadystatechange=function() {
                        if (xmlhttp.readyState == 4) {
                                if (xmlhttp.status == 200) {
                                        var aNode = xmlhttp.responseText;
										var nameArr = aNode.split(',');
										saveLat(nameArr[0]);
										saveLon(nameArr[1]);
										qrCodeTimer.running = false;
										qdialog.showDialog(qdialog.SizeLarge, "NL alert configurate mededeling", "Lengtegraad " + nameArr[1] + " en breedtegraad " + nameArr[0] + " ontvangen vanuit telefoon");	
				}
			}
		}
                xmlhttp.open("GET", "http://qutility.nl/geolocation/toon/"+qrCodeID+".geo", true);
                xmlhttp.send();

	}
	
	Text {
		id: title
		text: "Invoeren GPS coordinaten (max 4 decimalen) voor de bepaling van regionale en lokale NL-Alert meldingen."
       		width: isNxt ? 500 : 400
        	wrapMode: Text.WordWrap
		font.pixelSize: isNxt ? 20 : 16
		font.family: qfont.semiBold.name
		color: colors.rbTitle

		anchors {
			left: lonButton.right
			leftMargin: 20
			top: lonButton.top
		}

	}

	EditTextLabel4421 {
		id: lonLabel
		width: isNxt ? 350 : 280
		height: isNxt ? 45 : 35
		leftText: "Lengtegraad:"
		leftTextAvailableWidth: isNxt ?  175 : 140

		anchors {
			left: parent.left
			leftMargin: 40
			top: parent.top
			topMargin: 30
		}

		onClicked: {
			qnumKeyboard.open("Lengtegraad", lonLabel.inputText, app.nlalertownLongitude, 1 , saveLon, validateCoordinate);
		}
	}

	IconButton {
		id: lonButton
		width: isNxt ? 50 : 40

		iconSource: "qrc:/tsc/edit.png"

		anchors {
			left: lonLabel.right
			leftMargin: 6
			top: lonLabel.top
		}

		bottomClickMargin: 3
		onClicked: {
			qnumKeyboard.open("Lengtegraad", lonLabel.inputText, app.nlalertownLongitude, 1 , saveLon, validateCoordinate);
		}
	}

	EditTextLabel4421 {
		id: latLabel
		width: lonLabel.width
		height: isNxt ? 45 : 35
		leftText: "Breedtegraad:"
		leftTextAvailableWidth: isNxt ?  175 : 140

		anchors {
			left: lonLabel.left
			top: lonLabel.bottom
			topMargin: 6
		}

		onClicked: {
			qnumKeyboard.open("Breedtegraad", latLabel.inputText, app.nlalertownLatitude, 1 , saveLat, validateCoordinate);
		}
	}

	IconButton {
		id: latButton
		width: isNxt ? 50 : 40
		iconSource: "qrc:/tsc/edit.png"

		anchors {
			left: latLabel.right
			leftMargin: 6
			top: latLabel.top
		}

		topClickMargin: 3
		onClicked: {
			qnumKeyboard.open("Breedtegraad", latLabel.inputText, app.nlalertownLatitude, 1 , saveLat, validateCoordinate);
		}
	}


	EditTextLabel4421 {
		id: durationLabel
		width: lonLabel.width
		height: isNxt ? 45 : 35
		leftText: "Tijdsduur:"
		leftTextAvailableWidth: isNxt ?  175 : 140

		anchors {
			left: lonLabel.left
			top: latLabel.bottom
//			topMargin: isNxt ? 65 : 50
			topMargin: 6
		}

		onClicked: {
			qnumKeyboard.open("Tijdsduur in uren", durationLabel.inputText, app.nlalertShowTileAlertsDurationHours, 1 , saveDuration, validateCoordinate);
		}
	}

	IconButton {
		id: durationButton
		width: isNxt ? 50 : 40
		iconSource: "qrc:/tsc/edit.png"

		anchors {
			left: durationLabel.right
			leftMargin: 6
			top: durationLabel.top
		}

		topClickMargin: 3
		onClicked: {
			qnumKeyboard.open("Tijdsduur in uren", durationLabel.inputText, app.nlalertShowTileAlertsDurationHours, 1 , saveDuration, validateCoordinate);
		}
	}

	Text {
		id: uitlegDuration
		text: "Geeft de maximaal verstreken tijdsduur in uren aan waarbij een alert nog wordt meegenomen in het overzicht op de Tegel. Waarde 0 neemt alles mee."
       		width: isNxt ? 500 : 400
			wrapMode: Text.WordWrap
		anchors {
			left: durationButton.right
			leftMargin: 20
			top: durationButton.top
		}
		font {
			family: qfont.semiBold.name
			pixelSize: isNxt ? 20 : 16
		}
		color: colors.rbTitle
	}

	Text {
		id: enableSystrayLabel
		width: isNxt ? 200 : 160
		height: isNxt ? 45 : 36
		text: "Icon in systray"
		font.family: qfont.semiBold.name
		font.pixelSize: isNxt ? 25 : 20
		anchors {
			left: lonLabel.left
			top: durationLabel.bottom
			topMargin: 10
		}
	}
	
	OnOffToggle {
		id: enableSystrayToggle
		height: isNxt ? 45 : 36
		anchors.left: enableSystrayLabel.right
		anchors.leftMargin: 10
		anchors.top: enableSystrayLabel.top
		leftIsSwitchedOn: false
		onSelectedChangedByUser: {
			if (isSwitchedOn) {
				app.enableSystray = true;
			} else {
				app.enableSystray = false;
			}
		}
	}

	QrCode {
        id: qrCode
        anchors {
            right: lonLabel.right
            top:enableSystrayLabel.bottom
	    topMargin:5
	}
        width: isNxt ? 125 : 100
        height: width
    }

    Text {
        id: qrCodeText
        width: isNxt ? 500 : 400
        wrapMode: Text.WordWrap
        anchors {
            left: uitlegDuration.left
            top: qrCode.top
        }
		text: "Scan deze qrcode met je telefoon om je locatie gegevens op te halen."
		font {
			family: qfont.semiBold.name
			pixelSize: isNxt ? 20 : 16
		}
		color: colors.rbTitle
    }


        Timer {
                id: qrCodeTimer
                interval: 1000
                triggeredOnStart: false
                running: false
                repeat: true
                onTriggered: checkLocation()
        }





}
