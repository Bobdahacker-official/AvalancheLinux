import QtQuick 2.15
import calamares.slideshow 1.0
Presentation {
    id: presentation
    function nextSlide() { presentation.goToNextSlide(); }
    Timer { interval: 15000; running: true; repeat: true; onTriggered: presentation.nextSlide() }
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0b2031"
            Text {
                anchors.centerIn: parent
                width: parent.width * 0.82
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: "#e7f6fa"
                font.pixelSize: 25
                text: qsTr("Welcome to AvalancheLinux\n\nA focused desktop for your everyday work. Discover your new system in Avalanche Center.")
            }
        }
    }
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#123449"
            Text {
                anchors.centerIn: parent
                width: parent.width * 0.82
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: "#e7f6fa"
                font.pixelSize: 25
                text: qsTr("Make it yours\n\nFind software collections, search the package archive and personalize your workspace with Avalanche Software and Settings.")
            }
        }
    }
}
