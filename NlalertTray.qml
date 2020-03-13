import QtQuick 2.1

import qb.components 1.0
import qb.base 1.0

SystrayIcon {
	id: nlalertSystrayIcon
	posIndex: 9000
	property string objectName: "nlalertSystray"
	visible: app.enableSystray

	onClicked: {
		stage.openFullscreen(app.nlalertScreenUrl);
	}

	Image {
		id: imgNewMessage
		anchors.centerIn: parent
		source: "file:///qmf/qml/apps/nlalert/drawables/nlalert-icon.png"
		width: 25
		height: 25
		fillMode: Image.PreserveAspectFit

	}
}
