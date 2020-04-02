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
		color: (typeof dimmableColors !== 'undefined') ? dimmableColors.waTileTextColor : colors.waTileTextColor
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
		color: (typeof dimmableColors !== 'undefined') ? dimmableColors.waTileTextColor : colors.waTileTextColor
       		visible: !dimState
	}

	Text {
		id: insideAreaText
		text: "Relevant voor u"
		anchors {
			baseline: parent.top
			baselineOffset: isNxt ? 62 : 50
			left: parent.left
			leftMargin:  isNxt ? 15 : 10 
		}
		font {
			family: qfont.bold.name
			pixelSize: isNxt ? 22 : 18
		}
		color: (typeof dimmableColors !== 'undefined') ? dimmableColors.waTileTextColor : colors.waTileTextColor
       	visible: !dimState
	}

	Text {
		id: insideAreaNumber
		text: app.nlalertInsideAreaAlerts
		anchors {
			top: insideAreaText.top
			right: parent.right
			rightMargin:  isNxt ? 25 : 20 
		}
		font {
			family: qfont.regular.name
			pixelSize: isNxt ? 22 : 18
		}
		color: (typeof dimmableColors !== 'undefined') ? dimmableColors.clockTileColor : colors.clockTileColor
        visible: !dimState
	}

	Text {
		id: outsideAreaText
		text: "Niet relevant voor u"
		anchors {
			left: insideAreaText.left
			top: insideAreaText.bottom
		}
		font {
			family: qfont.bold.name
			pixelSize: isNxt ? 22 : 18
		}
		color: (typeof dimmableColors !== 'undefined') ? dimmableColors.waTileTextColor : colors.waTileTextColor
       	visible: !dimState
	}

	Text {
		id: outsideAreaNumber
		text: app.nlalertOutsideAreaAlerts
		anchors {
			top: outsideAreaText.top
			left: insideAreaNumber.left
		}
		font {
			family: qfont.regular.name
			pixelSize: isNxt ? 18 : 15
		}
		color: (typeof dimmableColors !== 'undefined') ? dimmableColors.clockTileColor : colors.clockTileColor
        visible: !dimState
	}

	Text {
		id: regioText
		text: "In uw regio"
		anchors {
			left: insideAreaText.left
			top: outsideAreaText.bottom
		}
		font {
			family: qfont.bold.name
			pixelSize: isNxt ? 22 : 18
		}
		color: (typeof dimmableColors !== 'undefined') ? dimmableColors.waTileTextColor : colors.waTileTextColor
       	visible: !dimState
	}

	Text {
		id: regioNumber
		text: app.nlalertRegioAlerts
		anchors {
			top: regioText.top
			left: insideAreaNumber.left
		}
		font {
			family: qfont.regular.name
			pixelSize: isNxt ? 18 : 15
		}
		color: (typeof dimmableColors !== 'undefined') ? dimmableColors.clockTileColor : colors.clockTileColor
        visible: !dimState
	}


	Text {
		id: statusText
		text: "Status"
		anchors {
			top: regioText.bottom
			horizontalCenter: parent.horizontalCenter
		}
		font {
			family: qfont.bold.name
			pixelSize: isNxt ? 22 : 18
		}
		color: (typeof dimmableColors !== 'undefined') ? dimmableColors.waTileTextColor : colors.waTileTextColor
       	visible: !dimState
	}

	Text {
		id: txtStatus
		text: app.tileStatus
		color: (typeof dimmableColors !== 'undefined') ? dimmableColors.clockTileColor : colors.clockTileColor
		anchors {
			top: statusText.bottom
			horizontalCenter: parent.horizontalCenter
		}
		font.pixelSize: isNxt ? 20 : 16
		font.family: qfont.italic.name
       	visible: !dimState
	}
	
	
	
}
