import "../services"
import "../core"
import "."
import QtQuick
import QtQuick.Effects

Canvas { // High-detail dual spectrum & wave visualizer
    id: root
    property list<var> points
    property list<var> smoothPoints
    property real maxVisualizerValue: 1000
    property int smoothing: 2
    property bool live: true
    property color color: Appearance.colors.colPrimary
    property color secondaryColor: Appearance.colors.colSecondary
    property real fillOpacity: 0.70
    property real strokeWidth: 3.0
    property real strokeOpacity: 0.95
    property real saturation: 1.3
    property real blurAmount: 0.1
    property string visualStyle: "bars" // unused, for compatibility with PlayerControl.qml props
    property int maxBars: 32

    property var peakHistory: []

    onPointsChanged: () => {
        root.requestPaint()
    }

    anchors.fill: parent
    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        var rawPts = root.points;
        var maxVal = root.maxVisualizerValue || 1;
        var h = height;
        var w = width;
        var n = rawPts.length;
        if (n < 2) return;

        var numBars = Math.min(48, n);
        var barGap = 3.0;
        var totalGap = barGap * (numBars - 1);
        var barWidth = Math.max(2.0, (w - totalGap) / numBars);

        // Smooth values & calculate peak caps
        var smoothVals = [];
        var pts = [];
        for (var i = 0; i < numBars; ++i) {
            var srcIdx = Math.floor(i * (n / numBars));
            var rawVal = rawPts[srcIdx] || 0;
            var val = (root.live ? rawVal : 0) / maxVal;
            val = Math.min(1.0, Math.max(0.0, val));
            smoothVals.push(val);

            var x = i * (barWidth + barGap);
            var barH = val * (h * 0.88);
            var y = h - barH;
            pts.push({ x: x + barWidth / 2, y: y });

            // Render Spectrum Bar with vertical gradient
            if (val > 0.01) {
                var barGrad = ctx.createLinearGradient(x, y, x, h);
                barGrad.addColorStop(0.0, Qt.rgba(root.color.r, root.color.g, root.color.b, root.fillOpacity));
                barGrad.addColorStop(0.5, Qt.rgba(root.secondaryColor.r, root.secondaryColor.g, root.secondaryColor.b, root.fillOpacity * 0.6));
                barGrad.addColorStop(1.0, Qt.rgba(root.secondaryColor.r, root.secondaryColor.g, root.secondaryColor.b, 0.05));

                ctx.fillStyle = barGrad;

                // Draw rounded top bar
                var radius = Math.min(barWidth / 2, 4);
                ctx.beginPath();
                ctx.moveTo(x + radius, y);
                ctx.lineTo(x + barWidth - radius, y);
                ctx.quadraticCurveTo(x + barWidth, y, x + barWidth, y + radius);
                ctx.lineTo(x + barWidth, h);
                ctx.lineTo(x, h);
                ctx.lineTo(x, y + radius);
                ctx.quadraticCurveTo(x, y, x + radius, y);
                ctx.closePath();
                ctx.fill();

                // Glowing peak cap dot/line
                ctx.fillStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, 0.95);
                ctx.beginPath();
                ctx.arc(x + barWidth / 2, y + 1.5, Math.min(barWidth / 2, 2.5), 0, 2 * Math.PI);
                ctx.fill();
            }
        }

        // Overlay: Smooth Bezier Crest Line along top of bars
        if (pts.length > 2 && root.strokeWidth > 0) {
            ctx.beginPath();
            ctx.moveTo(pts[0].x, pts[0].y);
            for (var j = 0; j < pts.length - 1; j++) {
                var midX = (pts[j].x + pts[j + 1].x) / 2;
                var midY = (pts[j].y + pts[j + 1].y) / 2;
                ctx.quadraticCurveTo(pts[j].x, pts[j].y, midX, midY);
            }
            ctx.lineTo(pts[pts.length - 1].x, pts[pts.length - 1].y);

            var strokeGrad = ctx.createLinearGradient(0, 0, w, 0);
            strokeGrad.addColorStop(0.0, Qt.rgba(root.color.r, root.color.g, root.color.b, root.strokeOpacity));
            strokeGrad.addColorStop(0.5, Qt.rgba(root.secondaryColor.r, root.secondaryColor.g, root.secondaryColor.b, root.strokeOpacity));
            strokeGrad.addColorStop(1.0, Qt.rgba(root.color.r, root.color.g, root.color.b, root.strokeOpacity));

            ctx.strokeStyle = strokeGrad;
            ctx.lineWidth = root.strokeWidth;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            ctx.stroke();
        }
    }

    layer.enabled: true
    layer.effect: MultiEffect {
        source: root
        saturation: root.saturation
        blurEnabled: root.blurAmount > 0
        blurMax: 7
        blur: root.blurAmount
    }
}
