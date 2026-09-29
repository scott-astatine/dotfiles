import Quickshell
import "../../components"

ScriptModel {
    required property int count
    values: Array(count).map((_, i) => i)
}
