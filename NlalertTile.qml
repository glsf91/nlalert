import QtQuick 2.1
import qb.components 1.0

Tile {
	id: nlalertTile

	onClicked: {
		stage.openFullscreen(app.nlalertScreenUrl);
	}

	Image {
		id: nlalertIcon1
		source: "file:///qmf/qml/apps/nlalert/drawables/nlalertTile.png"
		anchors {
			baseline: parent.top
			baselineOffset: 10
			horizontalCenter: parent.horizontalCenter
		}
		width: 100 
		height: 100
		fillMode: Image.PreserveAspectFit
		cache: false
       	visible: dimState ? app.nlalertIconShow : false	
	}

	Text {
		id: nlalertIcon1Text
		text: "nl-alert"
		anchors {
			top: nlalertIcon1.bottom
			horizontalCenter: parent.horizontalCenter
		}
		font {
			family: qfont.bold.name
			pixelSize: isNxt ? 25 : 20
		}
		color: colors.waTileTextColor
       	visible: dimState ? app.nlalertIconShow : false	
	}



	Text {
		id: tiletitle
		text: "NL-Alert"
		anchors {
			baseline: parent.top
			baselineOffset: isNxt ? 30 : 24
			horizontalCenter: parent.horizontalCenter
		}
		font {
			family: qfont.bold.name
			pixelSize: isNxt ? 25 : 20
		}
		color: colors.waTileTextColor
       		visible: !dimState
	}

	Text {
		id: localText
		text: "Lokaal"
		anchors {
			baseline: parent.top
			baselineOffset: isNxt ? 62 : 50
			left: parent.left
			leftMargin:  isNxt ? 25 : 20 
		}
		font {
			family: qfont.bold.name
			pixelSize: isNxt ? 22 : 18
		}
		color: colors.waTileTextColor
       	visible: !dimState
	}

	Text {
		id: localNumber
		text: app.nlalertLocalAlerts
		anchors {
			top: localText.top
			right: parent.right
			rightMargin:  isNxt ? 25 : 20 
		}
		font {
			family: qfont.regular.name
			pixelSize: isNxt ? 22 : 18
		}
		color: colors.clockTileColor
        visible: !dimState
	}

	Text {
		id: regioText
		text: "Regio"
		anchors {
			left: localText.left
			top: localText.bottom
		}
		font {
			family: qfont.bold.name
			pixelSize: isNxt ? 22 : 18
		}
		color: colors.waTileTextColor
       	visible: !dimState
	}

	Text {
		id: regioNumber
		text: app.nlalertRegioAlerts
		anchors {
			top: regioText.top
			left: localNumber.left
		}
		font {
			family: qfont.regular.name
			pixelSize: isNxt ? 18 : 15
		}
		color: colors.clockTileColor
        visible: !dimState
	}

	Text {
		id: allText
		text: "Alles"
		anchors {
			left: localText.left
			top: regioText.bottom
		}
		font {
			family: qfont.bold.name
			pixelSize: isNxt ? 22 : 18
		}
		color: colors.waTileTextColor
       	visible: !dimState
	}

	Text {
		id: allNumber
		text: app.nlalertAllAlerts
		anchors {
			top: allText.top
			left: localNumber.left
		}
		font {
			family: qfont.regular.name
			pixelSize: isNxt ? 18 : 15
		}
		color: colors.clockTileColor
        visible: !dimState
	}

	Text {
		id: statusText
		text: "Status"
		anchors {
			top: allText.bottom
			horizontalCenter: parent.horizontalCenter
		}
		font {
			family: qfont.bold.name
			pixelSize: isNxt ? 22 : 18
		}
		color: colors.waTileTextColor
       	visible: !dimState
	}

	Text {
		id: txtStatus
		text: app.tileStatus
		color: colors.clockTileColor
		anchors {
			top: statusText.bottom
			horizontalCenter: parent.horizontalCenter
		}
		font.pixelSize: isNxt ? 20 : 16
		font.family: qfont.italic.name
       	visible: !dimState
	}
	
	
	
}
