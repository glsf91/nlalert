import QtQuick 2.1
import qb.components 1.0

Rectangle {

    function colorDistance(distance) {
        if (distance > app.nlalertRegioRange) {
            return "#00FF00"
        } else {
            return "#FF0000"
        }
    }


	width: isNxt ? 850 : 646
	height: isNxt ? 94 : 73
	color: colors.background

	Text {
		id: txtAlertTime
		x: 10
		anchors {
			top: parent.top
			left: parent.left
			leftMargin: 5
		}
		text: alertTime
		font.family: qfont.semiBold.name
		font.pixelSize: isNxt ? 20 : 16
	}

/*	Text {
		id: txtAlertLocation
		anchors.left: txtAlertTime.right
		anchors.leftMargin: 10
		anchors.right: txtDistance.left
		anchors.rightMargin: 10
		anchors.bottom: txtAlertTime.bottom
		clip: true
		text: alertLocation
		font.family: qfont.semiBold.name
		font.pixelSize: isNxt ? 20 : 16
	}

	Text {
		id: txtDistance
		anchors {
			top: parent.top
			right: parent.right
			rightMargin: 5
		}
		text: " " + distance +  " km"
		font.family: qfont.semiBold.name
		font.pixelSize: isNxt ? 20 : 16
		color: colorDistance(distance)
	}
*/
	Text {
		id:txtDescription
		x: 10
		anchors {
			top: txtAlertTime.bottom
			left: txtAlertTime.left
		}
		width: parent.width -10
		text: description
		wrapMode: Text.WordWrap
		maximumLineCount: 3
		elide: Text.ElideRight
		lineHeight: 0.8
		font.family: qfont.italic.name
		font.pixelSize: isNxt ? 18 : 14
	}
}