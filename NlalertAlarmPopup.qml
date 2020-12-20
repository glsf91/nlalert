import QtQuick 2.1

import qb.base 1.0
import qb.components 1.0

Popup {
	id: alarmPopup

	property string curState: ""
	property string messageText : ""
	
	onShown: {
		bigText.text = "NL-Alert alarm";
		background.color = "#cc3300"; 
		smallText.text = messageText;
	
	}

	Rectangle {
		id: background
		anchors.fill: parent
		color: "#cc3300"; 
	}

	Image {
		id: nlalertImg
		anchors {
			horizontalCenter: parent.horizontalCenter
			top: parent.top
			topMargin: Math.round(100 * verticalScaling)
		}
		source: "file:///qmf/qml/apps/nlalert/drawables/nlalertAlarm.png"
	}

	Text {
		id: bigText
		anchors {
			horizontalCenter: parent.horizontalCenter
			top: parent.top
			topMargin: Math.round(270 * verticalScaling)
		}
		color: colors.white
		font {
			pixelSize: 40 // qfont.smokeDetectorAlarmText
			family: qfont.semiBold.name
		}
	}

	Text {
		id: smallText
		anchors {
			horizontalCenter: parent.horizontalCenter
			top: bigText.baseline
			topMargin: 20
		}
		color: colors.white

		width: parent.width -10
		wrapMode: Text.WordWrap
		maximumLineCount: 4
		elide: Text.ElideRight
		font.family: qfont.italic.name
		font.pixelSize: isNxt ? 24 : 20

	}

	MouseArea {
		id: nonClickableArea
		anchors.fill: parent
	}

	Rectangle {
		id: closeButtonBackground
		anchors {
			top: parent.top
			topMargin: designElements.vMargin20
			right: parent.right
			rightMargin: anchors.topMargin
		}
		width: Math.round(50 * horizontalScaling)
		height: width
		radius: width / 2
		opacity: 0.1
		color: "white"
	}

	Image {
		id: closeButton
		anchors.centerIn: closeButtonBackground
		source: "file:///qmf/qml/apps/nlalert/drawables/close-circle-cross.svg"
	}

	MouseArea {
		anchors.centerIn: closeButtonBackground
		width: closeButtonBackground.width + designElements.hMargin20
		height: width
		property string kpiId: curState + ".close"

		onPressed: closeButtonBackground.color = "black"
		onReleased: closeButtonBackground.color = "white"
		onClicked: {
			alarmPopup.hide();
			stage.openFullscreen(app.nlalertScreenUrl);
		}
	}
}
