import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes 
import org.qfield
import org.qgis
import Theme
import "."

Item {
    id: plugin
    property var mainWindow: iface.mainWindow()

    // --- 1. TRADUCTIONS  ---
    property string currentLang: Qt.locale().name.substring(0, 2)
    function tr(key) {
        var translations = {
            // Section Position
            "pos_label":       { "en": "Fill",               "fr": "Remplissage" },
            "pos_desc":        { "en": "Arrow & Dot",        "fr": "Flèche & Point" },
            "stroke_label":    { "en": "Borders",            "fr": "Bordures" },
            "stroke_desc":     { "en": "Arrow & Dot",        "fr": "Flèche & Point" },
            "acc_border_c":    { "en": "Border Color",       "fr": "Couleur bordure" },
            "acc_border_d":    { "en": "Accuracy circle",    "fr": "Cercle de précision" },
            "pos_tint":        { "en": "Position Settings",  "fr": "Réglages Position" },
            "reset":           { "en": "Reset",              "fr": "Réinitialiser" },
            "apply":           { "en": "Apply",              "fr": "Appliquer" },
            "arrow_size":      { "en": "Arrow Size",         "fr": "Taille flèche" },
            "arrow_w":         { "en": "Arrow Border Width", "fr": "Épaisseur bordure (flèche)" },
            "dot_w":           { "en": "Dot Border Width",   "fr": "Épaisseur bordure (point)" },
            "acc_w":           { "en": "Acc. Border Width",  "fr": "Épaisseur cercle" },
            "dot_size":        { "en": "Dot Size",           "fr": "Taille Point" },
            "dot_s_desc":      { "en": "Diameter",           "fr": "Diamètre" },
            
            // Section Viseur / Crosshair
            "cross_c":         { "en": "Crosshair Color",    "fr": "Couleur curseur" },
            "cross_c_desc":    { "en": "Center line",        "fr": "Remplissage" },
            "cross_b":         { "en": "Border Color",       "fr": "Couleur Bordure" },
            "cross_b_desc":    { "en": "Outline",            "fr": "Bordure" },
            "cross_s":         { "en": "Crosshair Size",     "fr": "Taille curseur de position" },
            "cross_w":         { "en": "Crosshair Width",    "fr": "Épaisseur curseur de position" },
            "cross_bw":        { "en": "Border Width",       "fr": "Épaisseur Bordure (curseur)" },
            
            // Onglets
            "tab_pos":         { "en": "Position",           "fr": "Position" },
            "tab_cross":       { "en": "Crosshair",          "fr": "Curseur de position" },
            "cancel":          { "en": "Cancel",             "fr": "Annuler" },
"color_code":      { "en": "Color code",         "fr": "Code couleur" }
        }
        var t = translations[key];
        if (t) return (currentLang === "fr") ? t.fr : t.en;
        return key;
    }

    // --- 2. CONFIGURATION ---
    property var positionColorConfig: ({
        // GROUPE POS
        "positionColor":           { "group": "pos", "name": tr("pos_label"),    "desc": tr("pos_desc"),     "type": "color" },
        "positionStrokeColor":     { "group": "pos", "name": tr("stroke_label"), "desc": tr("stroke_desc"),  "type": "color" },
        "accuracyBorderColor":     { "group": "pos", "name": tr("acc_border_c"), "desc": tr("acc_border_d"), "type": "color" },
        "movementSize":            { "group": "pos", "name": tr("arrow_size"),   "desc": "", "type": "number", "min": 10, "max": 60, "step": 1 },
        "movementStrokeWidth":     { "group": "pos", "name": tr("arrow_w"),      "desc": "", "type": "number", "min": 0, "max": 10, "step": 0.1 },
        "positionMarkerSize":      { "group": "pos", "name": tr("dot_size"),     "desc": tr("dot_s_desc"),   "type": "number", "min": 5, "max": 40, "step": 1 },
        "positionBorderWidth":     { "group": "pos", "name": tr("dot_w"),        "desc": "",   "type": "number", "min": 0, "max": 5, "step": 0.1 },
        "accuracyBorderWidth":     { "group": "pos", "name": tr("acc_w"),        "desc": "",   "type": "number", "min": 0, "max": 5, "step": 0.1 },
        
        // GROUPE CROSS (Viseur)
        "crosshairColor":          { "group": "cross", "name": tr("cross_c"),      "desc": tr("cross_c_desc"), "type": "color" },
        "crosshairBorderColor":    { "group": "cross", "name": tr("cross_b"),      "desc": tr("cross_b_desc"), "type": "color" },
        "crosshairSize":           { "group": "cross", "name": tr("cross_s"),      "desc": "", "type": "number", "min": 20, "max": 100, "step": 2 },
        "crosshairWidth":          { "group": "cross", "name": tr("cross_w"),      "desc": "", "type": "number", "min": 1, "max": 10, "step": 0.1 },
        "crosshairBorderWidth":    { "group": "cross", "name": tr("cross_bw"),     "desc": "", "type": "number", "min": 0, "max": 5, "step": 0.1 }
    })

    property var allKeys: Object.keys(positionColorConfig)
    
    // Filtres pour les onglets
    property var posColorKeys: allKeys.filter(function(k){ return positionColorConfig[k].group === 'pos' && positionColorConfig[k].type === 'color' })
    property var posSliderKeys: allKeys.filter(function(k){ return positionColorConfig[k].group === 'pos' && positionColorConfig[k].type === 'number' })
    
    property var crossColorKeys: allKeys.filter(function(k){ return positionColorConfig[k].group === 'cross' && positionColorConfig[k].type === 'color' })
    property var crossSliderKeys: allKeys.filter(function(k){ return positionColorConfig[k].group === 'cross' && positionColorConfig[k].type === 'number' })
    
    property var defaultColors: ({
        "positionColor": "#3388FF",           
        "positionStrokeColor": "#FFFFFF",
        "accuracyBorderColor": "#3388FF",
        "movementSize": 30.0,
        "movementStrokeWidth": 1.8,
        "positionMarkerSize": 15.0,
        "positionBorderWidth": 1.7,
        "accuracyBorderWidth": 0.7,
        "crosshairColor": "#000000",
        "crosshairBorderColor": "#FFFFFF",
        "crosshairSize": 50.0,
        "crosshairWidth": 2.4,
        "crosshairBorderWidth": 1.1
    })

    Settings {
        id: themeSettings
        category: "PositionPlugin"
        property string jsonColors: "{}" 
    }

    // --- 3. LOGIQUE MÉTIER (Marker + Crosshair) ---
       // --- Logique button---
    function findGnssButton(parent) {
        if (!parent || !parent.children) return null;
        for (var i = 0; i < parent.children.length; i++) {
            var child = parent.children[i];
            if (child.hasOwnProperty("followActive") && child.hasOwnProperty("autoRefollow")) return child;
            var res = findGnssButton(child);
            if (res) return res;
        }
        return null;
    }

    function updatePositionButton(key, value) {
        if (key !== "positionColor") return;
        var btn = findGnssButton(mainWindow.contentItem);
        if (btn) {
            btn.iconColor = Qt.binding(function() { return btn.followActive ? Theme.toolButtonColor : value });
            btn.bgcolor = Qt.binding(function() { return btn.followActive ? value : Theme.toolButtonBackgroundColor });
        }
    }

    // --- Logique Position (Marker) ---
    function findLocationMarker(parent) {
        if (!parent || !parent.children) return null;
        for (var i = 0; i < parent.children.length; i++) {
            var child = parent.children[i];
            if (child.toString().indexOf("LocationMarker") !== -1) return child;
            var res = findLocationMarker(child);
            if (res) return res;
        }
        return null;
    }

    function updateLiveMarker(key, value) {
        var mapCanvas = iface.findItemByObjectName('mapCanvasContainer');
        if (!mapCanvas) return;
        var marker = findLocationMarker(mapCanvas);
        if (!marker) return;

        if (key === "positionColor") marker.color = value;
        if (key === "positionStrokeColor") marker.strokeColor = value;

        for (var i = 0; i < marker.children.length; i++) {
            var child = marker.children[i];
            try {
                var childStr = child.toString();
                var isPosMarker = (childStr.indexOf("Rectangle") !== -1 && child.hasOwnProperty("layer"));
                var isMovementMarker = (childStr.indexOf("Shape") !== -1); 

                if (isPosMarker) {
                    if (child.layer && child.layer.enabled) { 
                         if (key === "positionMarkerSize") { child.width = Number(value); child.height = Number(value); child.radius = Number(value) / 2; }
                         if (key === "positionBorderWidth") child.border.width = Number(value);
                         if (key === "positionStrokeColor") child.border.color = value;
                    } else { 
                         if (key === "accuracyBorderWidth" && child.border) child.border.width = Number(value);
                         if (key === "accuracyBorderColor" && child.border) child.border.color = value;
                    }
                }
                if (isMovementMarker) {
                    if (key === "movementSize") child.scale = Number(value) / 26.0;
                    if (key === "movementStrokeWidth" && child.data) {
                        for (var j = 0; j < child.data.length; j++) 
                            if (child.data[j].hasOwnProperty("strokeWidth")) child.data[j].strokeWidth = Number(value);
                    }
                    if (key === "positionStrokeColor" && child.data) {
                        for (var k = 0; k < child.data.length; k++) 
                            if (child.data[k].hasOwnProperty("strokeColor")) child.data[k].strokeColor = value;
                    }
                }
            } catch(e) {}
        }
    }

    // --- Logique Crosshair (Viseur) ---
    function findLocatorItem(parent) {
        if (!parent || !parent.children) return null;
        for (var i = 0; i < parent.children.length; i++) {
            var child = parent.children[i];
            if (child.hasOwnProperty("snappingUtils") || child.toString().indexOf("Locator") !== -1) {
                for(var j=0; j<child.children.length; j++) {
                     if(child.children[j].toString().indexOf("Shape") !== -1) return child;
                }
            }
            var res = findLocatorItem(child);
            if (res) return res;
        }
        return null;
    }

    function updateCrosshair(key, value) {
        if (key.indexOf("crosshair") === -1) return;

        var locator = findLocatorItem(mainWindow.contentItem);
        if (!locator) return;

        var crosshairCircle = null;
        for(var i=0; i<locator.children.length; i++) {
            if(locator.children[i].toString().indexOf("Shape") !== -1) {
                crosshairCircle = locator.children[i];
                break;
            }
        }
        if (!crosshairCircle) return;

        if (key === "crosshairSize") {
             crosshairCircle.width = Number(value);
             crosshairCircle.height = Number(value);
        }

        var paths = crosshairCircle.data; 
        var shapePaths = [];
        for(var p=0; p<paths.length; p++) {
            if(paths[p].toString().indexOf("ShapePath") !== -1) shapePaths.push(paths[p]);
        }
        
        var bufferPath = null;
        var mainPath = null;

        if (shapePaths.length >= 2) {
            bufferPath = shapePaths[0];
            mainPath = shapePaths[1];
        } else if (shapePaths.length === 1) {
            mainPath = shapePaths[0];
        }

        if (mainPath && key === "crosshairColor") mainPath.strokeColor = value;
        if (bufferPath && key === "crosshairBorderColor") bufferPath.strokeColor = value;
        
        if (key === "crosshairWidth" || key === "crosshairBorderWidth") {
            var wMain = (key === "crosshairWidth") ? Number(value) : Number(getCurrentValue("crosshairWidth"));
            var wBorder = (key === "crosshairBorderWidth") ? Number(value) : Number(getCurrentValue("crosshairBorderWidth"));
            
            if (mainPath) mainPath.strokeWidth = wMain;
            if (bufferPath) bufferPath.strokeWidth = wMain + (wBorder * 2);
        }
    }

    // --- Gestion des changements ---
    function applyChange(key, value) {
        try {
            if (key === undefined || key === "") return;
            var currentJson = themeSettings.jsonColors || "{}";
            var colorsObj = JSON.parse(currentJson);
            colorsObj[key] = value;
            if (positionPluginRoot.positionColorConfig[key].type === "color" && Theme.hasOwnProperty(key)) Theme.applyColors(colorsObj); 
            updateLiveMarker(key, value);
            updateCrosshair(key, value);
            updatePositionButton(key, value);
            themeSettings.jsonColors = JSON.stringify(colorsObj);
        } catch (e) { iface.logMessage("Erreur application: " + e); }
    }

    function getCurrentValue(key) {
        var saved = JSON.parse(themeSettings.jsonColors || "{}")[key];
        if (saved !== undefined) return saved;
        var conf = plugin.positionColorConfig[key];
        if (conf.type === "color" && Theme.hasOwnProperty(key)) {
             return Theme[key].toString();
        }
        return plugin.defaultColors[key];
    }

    // --- 4. INTERFACE UTILISATEUR ---

    // Bouton Toolbar
    QfToolButton {
        id: openColorsBtn
        iconSource: 'icon.svg'
        iconColor: Theme.mainColor
        bgcolor: Theme.darkGray
        round: true
        onClicked: positionColorDialog.open()
    }

    // --- COLOR WHEEL PICKER (partagé pour toutes les couleurs) ---
    property string _editingKey: ""

    Popup {
        id: colorWheelPopup
        parent: mainWindow.contentItem
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding: 0
        x: (parent.width  - width)  / 2
        y: (parent.height - height) / 2
        width: 280

        background: Rectangle {
            color: "white"; border.color: Theme.mainColor; border.width: 3; radius: 15
        }

        // --- État HSV ---
        property real _hue: 0
        property real _sat: 0
        property real _val: 1

        function openFor(key) {
            plugin._editingKey = key
            var hex = plugin.getCurrentValue(key)
            _fromHex(hex)
            _updateAll()
            open()
        }

        function _applyColor() {
            var hex = _hsvToHex(_hue, _sat, _val)
            plugin.applyChange(plugin._editingKey, hex)
        }

        function _fromHex(hex) {
            if (!hex || hex.toString().length < 6) return
            var h = hex.toString()
            if (h.charAt(0) !== '#') h = '#' + h
            if (h.length === 9) h = '#' + h.slice(3)
            var r = parseInt(h.slice(1,3), 16) / 255
            var g = parseInt(h.slice(3,5), 16) / 255
            var b = parseInt(h.slice(5,7), 16) / 255
            var max = Math.max(r,g,b), min = Math.min(r,g,b), d = max - min
            _val = max; _sat = max === 0 ? 0 : d / max
            if (d === 0) _hue = 0
            else if (max === r) _hue = 60 * (((g-b)/d) % 6)
            else if (max === g) _hue = 60 * ((b-r)/d + 2)
            else _hue = 60 * ((r-g)/d + 4)
            if (_hue < 0) _hue += 360
            cwHexField.text = _hsvToHex(_hue, _sat, _val).toUpperCase()
        }

        function _hsvToHex(h, s, v) {
            var r, g, b
            var i = Math.floor(h/60) % 6
            var f = h/60 - Math.floor(h/60)
            var p=v*(1-s), q=v*(1-f*s), t=v*(1-(1-f)*s)
            if      (i===0){r=v;g=t;b=p} else if(i===1){r=q;g=v;b=p}
            else if (i===2){r=p;g=v;b=t} else if(i===3){r=p;g=q;b=v}
            else if (i===4){r=t;g=p;b=v} else{r=v;g=p;b=q}
            function toH(x) { return Math.round(x*255).toString(16).padStart(2,'0').toUpperCase() }
            return '#' + toH(r) + toH(g) + toH(b)
        }

        function _updateAll() {
            cwWheelCanvas.requestPaint()
            cwBrightCanvas.requestPaint()
            var hex = _hsvToHex(_hue, _sat, _val)
            cwHexField.text = hex
            cwPreview.color = hex
        }

        onOpened: _updateAll()

        ColumnLayout {
            id: cwMainCol
            width: 280
            spacing: 0

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 12
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.bottomMargin: 12
                spacing: 10

                // ── Roue : couronne hue + triangle S/V ──
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    width: 240; height: 240

                    Canvas {
                        id: cwWheelCanvas
                        width: 240; height: 240
                        readonly property real cx:      120
                        readonly property real cy:      120
                        readonly property real outerR:  116
                        readonly property real innerR:  96
                        readonly property real ringMid: (outerR + innerR) / 2

                        function hsvToRgb(h, s, v) {
                            var r,g,b, i=Math.floor(h/60)%6, f=h/60-Math.floor(h/60)
                            var p=v*(1-s),q=v*(1-f*s),t=v*(1-(1-f)*s)
                            if(i===0){r=v;g=t;b=p}else if(i===1){r=q;g=v;b=p}
                            else if(i===2){r=p;g=v;b=t}else if(i===3){r=p;g=q;b=v}
                            else if(i===4){r=t;g=p;b=v}else{r=v;g=p;b=q}
                            return [Math.round(r*255),Math.round(g*255),Math.round(b*255)]
                        }

                        function triVerts() {
                            var h0 = colorWheelPopup._hue * Math.PI / 180
                            var h1 = h0 + 2*Math.PI/3
                            var h2 = h0 + 4*Math.PI/3
                            return [
                                { x: cx + innerR*Math.cos(h0), y: cy + innerR*Math.sin(h0) },
                                { x: cx + innerR*Math.cos(h1), y: cy + innerR*Math.sin(h1) },
                                { x: cx + innerR*Math.cos(h2), y: cy + innerR*Math.sin(h2) }
                            ]
                        }

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)

                            // ── Couronne hue ──
                            for (var angle = 0; angle < 360; angle++) {
                                var sa = (angle - 0.5) * Math.PI / 180
                                var ea = (angle + 1.5) * Math.PI / 180
                                var rgb = hsvToRgb(angle, 1, 1)
                                ctx.beginPath()
                                ctx.moveTo(cx + innerR*Math.cos(sa), cy + innerR*Math.sin(sa))
                                ctx.arc(cx, cy, outerR, sa, ea)
                                ctx.arc(cx, cy, innerR, ea, sa, true)
                                ctx.closePath()
                                ctx.fillStyle = "rgb("+rgb[0]+","+rgb[1]+","+rgb[2]+")"
                                ctx.fill()
                            }
                            ctx.beginPath(); ctx.arc(cx,cy,outerR,0,Math.PI*2)
                            ctx.strokeStyle="#777"; ctx.lineWidth=1; ctx.stroke()
                            ctx.beginPath(); ctx.arc(cx,cy,innerR,0,Math.PI*2)
                            ctx.strokeStyle="#777"; ctx.lineWidth=1; ctx.stroke()

                            // ── Triangle intérieur ──
                            var vt = triVerts()
                            var t0=vt[0], t1=vt[1], t2=vt[2]
                            function triPath() {
                                ctx.beginPath()
                                ctx.moveTo(t0.x,t0.y); ctx.lineTo(t1.x,t1.y)
                                ctx.lineTo(t2.x,t2.y); ctx.closePath()
                            }
                            var rgb0 = hsvToRgb(colorWheelPopup._hue, 1, 1)
                            triPath(); ctx.fillStyle="rgb("+rgb0[0]+","+rgb0[1]+","+rgb0[2]+")"; ctx.fill()

                            var mid01x=(t0.x+t2.x)/2, mid01y=(t0.y+t2.y)/2
                            var gw = ctx.createLinearGradient(t1.x,t1.y, mid01x,mid01y)
                            gw.addColorStop(0,"rgba(255,255,255,1)"); gw.addColorStop(1,"rgba(255,255,255,0)")
                            triPath(); ctx.fillStyle=gw; ctx.fill()

                            var mid02x=(t0.x+t1.x)/2, mid02y=(t0.y+t1.y)/2
                            var gb = ctx.createLinearGradient(t2.x,t2.y, mid02x,mid02y)
                            gb.addColorStop(0,"rgba(0,0,0,1)"); gb.addColorStop(1,"rgba(0,0,0,0)")
                            triPath(); ctx.fillStyle=gb; ctx.fill()

                            triPath(); ctx.strokeStyle="rgba(0,0,0,0.25)"; ctx.lineWidth=1; ctx.stroke()
                        }

                        MouseArea {
                            anchors.fill: parent
                            onPressed:         _handle(mouseX, mouseY)
                            onPositionChanged: if (pressed) _handle(mouseX, mouseY)
                            function _handle(mx, my) {
                                var dx=mx-cwWheelCanvas.cx, dy=my-cwWheelCanvas.cy
                                var dist=Math.sqrt(dx*dx+dy*dy)
                                if (dist >= cwWheelCanvas.innerR && dist <= cwWheelCanvas.outerR) {
                                    colorWheelPopup._hue = ((Math.atan2(dy,dx)*180/Math.PI)+360)%360
                                    colorWheelPopup._updateAll(); return
                                }
                                if (dist < cwWheelCanvas.innerR) {
                                    var vt = cwWheelCanvas.triVerts()
                                    var t0=vt[0], t1=vt[1], t2=vt[2]
                                    var denom = (t1.y-t2.y)*(t0.x-t2.x) + (t2.x-t1.x)*(t0.y-t2.y)
                                    if (Math.abs(denom) < 0.001) return
                                    var a = ((t1.y-t2.y)*(mx-t2.x) + (t2.x-t1.x)*(my-t2.y)) / denom
                                    var b = ((t2.y-t0.y)*(mx-t2.x) + (t0.x-t2.x)*(my-t2.y)) / denom
                                    var c = 1-a-b
                                    a=Math.max(0,a); b=Math.max(0,b); c=Math.max(0,c)
                                    var sum=a+b+c; a/=sum; b/=sum; c/=sum
                                    var newV = a+b
                                    colorWheelPopup._val = Math.max(0, Math.min(1, newV))
                                    colorWheelPopup._sat = Math.max(0, Math.min(1, newV > 0.001 ? a/newV : 0))
                                    colorWheelPopup._updateAll()
                                }
                            }
                        }
                    }

                    // Curseur couronne
                    Rectangle {
                        property real rad: colorWheelPopup._hue * Math.PI / 180
                        x: cwWheelCanvas.cx + cwWheelCanvas.ringMid * Math.cos(rad) - 8
                        y: cwWheelCanvas.cy + cwWheelCanvas.ringMid * Math.sin(rad) - 8
                        width: 16; height: 16; radius: 8
                        color: "transparent"
                        border.color: "white"; border.width: 2.5
                        antialiasing: true
                    }

                    // Curseur triangle
                    Rectangle {
                        property var verts: cwWheelCanvas.triVerts()
                        property var p0: verts[0]; property var p1: verts[1]; property var p2: verts[2]
                        property real sv: colorWheelPopup._sat
                        property real vv: colorWheelPopup._val
                        property real px: vv*(sv*p0.x + (1-sv)*p1.x) + (1-vv)*p2.x
                        property real py: vv*(sv*p0.y + (1-sv)*p1.y) + (1-vv)*p2.y
                        x: px - 8; y: py - 8
                        width: 16; height: 16; radius: 8
                        color: cwPreview.color
                        border.color: "white"; border.width: 2.5
                        antialiasing: true
                    }
                }

                Canvas { id: cwBrightCanvas; width:1; height:1; visible:false; onPaint:{} }

                // ── Aperçu + hex ──
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Rectangle {
                        id: cwPreview
                        width: 44; height: 44; radius: 22
                        color: "#FF0000"
                        border.color: "#aaa"; border.width: 2
                        antialiasing: true
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Label { text: plugin.tr("color_code"); font.pixelSize: 10; color: "#888" }
                        TextField {
                            id: cwHexField
                            Layout.fillWidth: true
                            text: "#FF0000"
                            maximumLength: 7
                            font.pixelSize: 14
                            leftPadding: 8
                            background: Rectangle {
                                color: "#f5f5f5"
                                border.color: cwHexField.activeFocus ? Theme.mainColor : "#ccc"
                                border.width: 1; radius: 6
                            }
                            color: "#333"
                            onAccepted: {
                                var v = text.trim()
                                if (v.charAt(0) !== '#') v = '#' + v
                                if (v.length === 7) { colorWheelPopup._fromHex(v); colorWheelPopup._updateAll() }
                            }
                        }
                    }
                }

                // ── Boutons ──
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Button {
    text: plugin.tr("cancel"); Layout.fillWidth: true
                        background: Rectangle { color: parent.down ? "#ddd" : "#eee"; radius: 15; border.color: "#ccc"; border.width: 1 }
                        contentItem: Text { text: parent.text; color: "#333"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        onClicked: colorWheelPopup.close()
                    }
                    Button {
                        text: "OK"; Layout.fillWidth: true
                        background: Rectangle { color: parent.down ? Qt.darker(Theme.mainColor,1.2) : Theme.mainColor; radius: 15 }
                        contentItem: Text { text: parent.text; color: "white"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        onClicked: { colorWheelPopup._applyColor(); colorWheelPopup.close() }
                    }
                }

            }   // ColumnLayout inner
        }   // ColumnLayout cwMainCol
    }   // colorWheelPopup

    
    Dialog {
        id: positionColorDialog
        modal: true
        visible: false
        parent: plugin.mainWindow.contentItem
        anchors.centerIn: parent 
        width: Math.min(500, parent.width * 0.95)
        
        
        background: Rectangle {
            color: Theme.mainBackgroundColor 
            radius: 20
            border.color: Theme.mainColor
            border.width: 2
        }

        contentItem: ColumnLayout {
            id: mainLayout
            spacing: 0
            
            // Titre
            Label {
                text: plugin.tr("pos_tint")
                font.bold: true; font.pixelSize: 18
                color: Theme.mainColor 
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 2
                Layout.bottomMargin: 5
            }

            // Onglets
            TabBar {
                id: bar
                Layout.fillWidth: true
                Layout.bottomMargin: 10
                TabButton { text: plugin.tr("tab_pos") }
                TabButton { text: plugin.tr("tab_cross") }
            }

            StackLayout {
                id: stack
                currentIndex: bar.currentIndex
                Layout.fillWidth: true
                // Hauteur dynamique selon l'onglet
                Layout.preferredHeight: bar.currentIndex === 0 ? colPos.implicitHeight : colCross.implicitHeight
                
                // --- ONGLET 1 : POSITION ---
                Item {
                    // Contraint la hauteur pour le scroll
                    implicitHeight: Math.min(colPos.implicitHeight, plugin.mainWindow.height * 0.6)
                    
                    ScrollView {
                        anchors.fill: parent
                        clip: true
                        contentWidth: availableWidth
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded
                        
                        ColumnLayout {
                            id: colPos
                            width: parent.width
                            spacing: 15 
                            // Couleurs
                            GridLayout {
                                Layout.fillWidth: true; columns: 2; columnSpacing: 10; rowSpacing: 10
                                Repeater { model: plugin.posColorKeys; delegate: colorDelegate }
                            }
                            // Sliders
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 8 
                                Repeater { model: plugin.posSliderKeys; delegate: sliderDelegate }
                            }
                        }
                    }
                }

                // --- ONGLET 2 : VISEUR (CROSSHAIR) ---
                Item {
                    implicitHeight: Math.min(colCross.implicitHeight, plugin.mainWindow.height * 0.6)
                    
                    ScrollView {
                        anchors.fill: parent
                        clip: true
                        contentWidth: availableWidth
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded
                        
                        ColumnLayout {
                            id: colCross 
                            width: parent.width
                            spacing: 15 
                            // Couleurs
                            GridLayout {
                                Layout.fillWidth: true; columns: 2; columnSpacing: 10; rowSpacing: 10
                                Repeater { model: plugin.crossColorKeys; delegate: colorDelegate }
                            }
                            // Sliders
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 8 
                                Repeater { model: plugin.crossSliderKeys; delegate: sliderDelegate }
                            }
                        }
                    }
                }
            }

            // Boutons Bas
            RowLayout {
                Layout.fillWidth: true; Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 10    
                Layout.bottomMargin: 2 
                spacing: 20
                Button {
                    text: plugin.tr("reset")
                    onClicked: {
                        themeSettings.jsonColors = "{}";
                        Theme.applyColors(plugin.defaultColors);
                        var keys = Object.keys(plugin.defaultColors);
                        for(var i=0; i<keys.length; i++) {
                            plugin.updateLiveMarker(keys[i], plugin.defaultColors[keys[i]]);

plugin.updatePositionButton(keys[i], plugin.defaultColors[keys[i]]);
                            plugin.updateCrosshair(keys[i], plugin.defaultColors[keys[i]]);
                        }
                    }
                }
                Button {
                    text: plugin.tr("apply")
                    highlighted: true
                    onClicked: positionColorDialog.close()
                }
            }
        }
    }

    // --- 5. COMPOSANTS RÉUTILISABLES  ---
    
    Component {
        id: colorDelegate
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            color: "#259E9E9E" 
            border.color: Theme.controlBorderColor; border.width: 1; radius: 6
            property string key: modelData
            property var conf: plugin.positionColorConfig[key]
            property var val: plugin.getCurrentValue(key)

            RowLayout {
                anchors.fill: parent; anchors.margins: 6; spacing: 2 
                Rectangle {
                    width: 18; height: 18; radius: 9
                    color: val
                    border.color: Theme.controlBorderColor; border.width: 1
                    Layout.rightMargin: 4
                }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0
                    Label { text: conf.name; font.bold: true; color: Theme.mainTextColor; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
                    Label { text: conf.desc; color: Theme.secondaryTextColor; font.pixelSize: 10; elide: Text.ElideRight; Layout.fillWidth: true }
                }
                Button {
                    display: AbstractButton.IconOnly
                    icon.source: "palette_icon.svg" 
                    icon.color: Theme.mainTextColor
                    icon.width: 24; icon.height: 24
                    Layout.preferredWidth: 40; Layout.preferredHeight: 40
                    background: Rectangle { color: parent.down ? Theme.controlBackgroundColor : "transparent"; radius: 4 }
                    onClicked: colorWheelPopup.openFor(key)
                }
            }
        }
    }

    Component {
        id: sliderDelegate
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            color: "#259E9E9E"
            border.color: Theme.controlBorderColor; border.width: 1; radius: 6
            property string key: modelData
            property var conf: plugin.positionColorConfig[key]
            property var val: Number(plugin.getCurrentValue(key))

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 4; spacing: 0
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: conf.desc !== "" ? conf.name + " (" + conf.desc + ")" : conf.name; font.bold: true; color: Theme.mainTextColor; font.pixelSize: 13; Layout.fillWidth: true }
                    Label { text: val.toLocaleString(Qt.locale(), 'f', 1); font.bold: true; color: Theme.mainTextColor }
                }
                Slider {
                    id: sControl
                    Layout.fillWidth: true; from: conf.min; to: conf.max; stepSize: conf.step; value: val
                    background: Rectangle {
                        x: sControl.leftPadding; y: sControl.topPadding + sControl.availableHeight / 2 - height / 2
                        width: sControl.availableWidth; height: 4; radius: 2; color: "#bdbebf"
                        Rectangle { width: sControl.visualPosition * parent.width; height: parent.height; color: Theme.mainColor; radius: 2 }
                    }
                    handle: Rectangle {
                        x: sControl.leftPadding + sControl.visualPosition * (sControl.availableWidth - width)
                        y: sControl.topPadding + sControl.availableHeight / 2 - height / 2
                        width: 16; height: 16; radius: 8
                        color: sControl.pressed ? Qt.darker(Theme.mainColor, 1.1) : Theme.mainColor
                        border.color: "white"; border.width: 2
                    }
                    onMoved: plugin.applyChange(key, value)
                }
            }
        }
    }

    // --- 6. INITIALISATION ---
    Component.onCompleted: {
        iface.addItemToPluginsToolbar(openColorsBtn);
        loadTimer.start();
    }
    
    Timer {
        id: loadTimer
        interval: 1000
        onTriggered: {
            try {
                var c = JSON.parse(themeSettings.jsonColors || "{}");
                var keys = Object.keys(c);
                if(keys.length > 0) {
                    Theme.applyColors(c);
                    for (var i = 0; i < keys.length; i++) {
                        plugin.updateLiveMarker(keys[i], c[keys[i]]);

plugin.updatePositionButton(keys[i], c[keys[i]]);
                        plugin.updateCrosshair(keys[i], c[keys[i]]);
                    }
                } else {
                    // Application des défauts pour le Crosshair si aucune config n'existe
                    var defKeys = Object.keys(plugin.defaultColors);
                    for (var j = 0; j < defKeys.length; j++) {
                       if (defKeys[j].indexOf("crosshair") !== -1)
                           plugin.updateCrosshair(defKeys[j], plugin.defaultColors[defKeys[j]]);
                    }
                }
            } catch(e) {}
        }
    }
}
