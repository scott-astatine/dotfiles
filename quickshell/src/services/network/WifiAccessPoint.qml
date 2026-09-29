import QtQuick
import "../../components"
import "../../core"
import ".."

QtObject {
    required property var lastIpcObject
    readonly property string ssid: lastIpcObject.ssid
    readonly property string bssid: lastIpcObject.bssid
    readonly property int strength: lastIpcObject.strength
    readonly property int frequency: lastIpcObject.frequency
    readonly property bool active: lastIpcObject.active
    readonly property string security: lastIpcObject.security
    readonly property bool isSecure: security.length > 0
    readonly property bool isSaved: (Network.savedSsids || []).includes(ssid)

    property bool askingPassword: false
}
