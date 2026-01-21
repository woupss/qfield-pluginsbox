import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Shapes
import org.qfield
import org.qgis
import Theme
import "."

Item {
    id: positionPluginRoot
    property var mainWindow: iface.mainWindow()

    function openSettings() {
        positionColorDialog.open()
    }

    // --- TRADUCTIONS ---
    property string currentLang: Qt.locale().name.substring(0, 2)
    function tr(key) {
        var translations = {
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
            
            // CROSSHAIR
            "cross_c":         { "en": "Crosshair Color",    "fr": "Couleur curseur" },
            "cross_c_desc":    { "en": "Center line",        "fr": "Remplissage" },
            "cross_b":         { "en": "Border Color",       "fr": "Couleur Bordure" },
            "cross_b_desc":    { "en": "Outline",            "fr": "Bordure" },
            "cross_s":         { "en": "Crosshair Size",     "fr": "Taille curseur de position" },
            "cross_w":         { "en": "Crosshair Width",    "fr": "Épaisseur curseur de position" },
            "cross_bw":        { "en": "Border Width",       "fr": "Épaisseur Bordure (curseur)" },
            
            "tab_pos":         { "en": "Position",           "fr": "Position" },
            "tab_cross":       { "en": "Crosshair",          "fr": "Curseur de position" }
        }
        var t = translations[key];
        if (t) return (currentLang === "fr") ? t.fr : t.en;
        return key;
    }

    // --- CONFIGURATION ---
    property var positionColorConfig: ({
        // GROUPE POS
        "positionColor":           { "group": "pos", "name": tr("pos_label"),    "desc": tr("pos_desc"),     "type": "color" },
        "positionStrokeColor":     { "group": "pos", "name": tr("stroke_label"), "desc": tr("stroke_desc"),  "type": "color" },
        "accuracyBorderColor":     { "group": "pos", "name": tr("acc_border_c"), "desc": tr("acc_border_d"), "type": "color" },
        "movementSize":            { "group": "pos", "name": tr("arrow_size"),   "desc": "", "type": "number", "min": 10, "max": 60, "step": 2 },
        "movementStrokeWidth":     { "group": "pos", "name": tr("arrow_w"),      "desc": "", "type": "number", "min": 0, "max": 10, "step": 0.5 },
        "positionMarkerSize":      { "group": "pos", "name": tr("dot_size"),     "desc": tr("dot_s_desc"),   "type": "number", "min": 5, "max": 40, "step": 1 },
        "positionBorderWidth":     { "group": "pos", "name": tr("dot_w"),        "desc": "",   "type": "number", "min": 0, "max": 5, "step": 0.1 },
        "accuracyBorderWidth":     { "group": "pos", "name": tr("acc_w"),        "desc": "",   "type": "number", "min": 0, "max": 5, "step": 0.1 },
        
        // GROUPE CROSS (Viseur)
        "crosshairColor":          { "group": "cross", "name": tr("cross_c"),      "desc": tr("cross_c_desc"), "type": "color" },
        "crosshairBorderColor":    { "group": "cross", "name": tr("cross_b"),      "desc": tr("cross_b_desc"), "type": "color" },
        "crosshairSize":           { "group": "cross", "name": tr("cross_s"),      "desc": "", "type": "number", "min": 20, "max": 100, "step": 5 },
        "crosshairWidth":          { "group": "cross", "name": tr("cross_w"),      "desc": "", "type": "number", "min": 1, "max": 10, "step": 0.5 },
        "crosshairBorderWidth":    { "group": "cross", "name": tr("cross_bw"),     "desc": "", "type": "number", "min": 0, "max": 5, "step": 0.5 }
    })

    property var allKeys: Object.keys(positionColorConfig)
    
    // Filtres
    property var posColorKeys: allKeys.filter(function(k){ return positionColorConfig[k].group === 'pos' && positionColorConfig[k].type === 'color' })
    property var posSliderKeys: allKeys.filter(function(k){ return positionColorConfig[k].group === 'pos' && positionColorConfig[k].type === 'number' })
    
    property var crossColorKeys: allKeys.filter(function(k){ return positionColorConfig[k].group === 'cross' && positionColorConfig[k].type === 'color' })
    property var crossSliderKeys: allKeys.filter(function(k){ return positionColorConfig[k].group === 'cross' && positionColorConfig[k].type === 'number' })
    
    property var defaultColors: ({
        "positionColor": "#3388FF",           
        "positionStrokeColor": "#FFFFFF",
        "accuracyBorderColor": "#3388FF",
        "movementSize": 26.0,
        "movementStrokeWidth": 3.0,
        "positionMarkerSize": 14.0,
        "positionBorderWidth": 2.0,
        "accuracyBorderWidth": 0.7,
        "crosshairColor": "#000000",
        "crosshairBorderColor": "#FFFFFF",
        "crosshairSize": 48.0,
        "crosshairWidth": 2.0,
        "crosshairBorderWidth": 1.0
    })

    // --- SAUVEGARDE ---
    Settings {
        id: themeSettings
        category: "PositionPlugin"
        property string jsonColors: "{}" 
    }

    // --- LOGIQUE METIER ---
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

    function applyChange(key, value) {
        try {
            if (key === undefined || key === "") return;
            var currentJson = themeSettings.jsonColors || "{}";
            var colorsObj = JSON.parse(currentJson);
            colorsObj[key] = value;
            
            if (positionPluginRoot.positionColorConfig[key].type === "color" && Theme.hasOwnProperty(key)) {
                Theme.applyColors(colorsObj); 
            }
            updateLiveMarker(key, value);
            updateCrosshair(key, value);
            themeSettings.jsonColors = JSON.stringify(colorsObj);
        } catch (e) { console.log("Erreur application: " + e); }
    }

    function getCurrentValue(key) {
        var saved = JSON.parse(themeSettings.jsonColors || "{}")[key];
        if (saved !== undefined) return saved;
        var conf = positionPluginRoot.positionColorConfig[key];
        if (conf.type === "color" && Theme.hasOwnProperty(key)) {
             return Theme[key].toString();
        }
        return positionPluginRoot.defaultColors[key];
    }

    // --- INTERFACE ---
    Popup {
        id: positionColorDialog
        modal: true
        visible: false
        parent: positionPluginRoot.mainWindow.contentItem
        anchors.centerIn: parent
        
        width: Math.min(500, parent.width * 0.95)
        height: Math.min(mainLayout.implicitHeight + 40, parent.height * 0.9)

        background: Rectangle {
            color: Theme.mainBackgroundColor
            radius: 8
            border.color: Theme.mainColor
            border.width: 2
        }

        contentItem: ColumnLayout {
            id: mainLayout
            spacing: 0
            
            Label {
                text: positionPluginRoot.tr("pos_tint")
                font.bold: true; font.pixelSize: 18
                color: Theme.mainTextColor 
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 5
                Layout.bottomMargin: 5
            }

            TabBar {
                id: bar
                Layout.fillWidth: true
                Layout.bottomMargin: 20
                TabButton { text: positionPluginRoot.tr("tab_pos") }
                TabButton { text: positionPluginRoot.tr("tab_cross") }
            }

            StackLayout {
                id: stack
                currentIndex: bar.currentIndex
                Layout.fillWidth: true
                Layout.preferredHeight: bar.currentIndex === 0 ? colPos.implicitHeight : colCross.implicitHeight
                
                // ONGLET 1 : POSITION
                Item {
                    implicitHeight: scrollColumnPos.implicitHeight 
                    ScrollView {
                        anchors.fill: parent
                        clip: true
                        contentWidth: availableWidth
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded
                        
                        ColumnLayout {
                            id: colPos
                            width: parent.width
                            spacing: 15 
                            GridLayout {
                                Layout.fillWidth: true; columns: 2; columnSpacing: 10; rowSpacing: 10
                                Repeater { model: positionPluginRoot.posColorKeys; delegate: colorDelegate }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 8 
                                Repeater { model: positionPluginRoot.posSliderKeys; delegate: sliderDelegate }
                            }
                        }
                    }
                }

                // ONGLET 2 : VISEUR
                Item {
                    implicitHeight: scrollColumnCross.implicitHeight 
                    ScrollView {
                        anchors.fill: parent
                        clip: true
                        contentWidth: availableWidth
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded
                        
                        ColumnLayout {
                            id: colCross 
                            width: parent.width
                            spacing: 15 
                            GridLayout {
                                Layout.fillWidth: true; columns: 2; columnSpacing: 10; rowSpacing: 10
                                Repeater { model: positionPluginRoot.crossColorKeys; delegate: colorDelegate }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 8 
                                Repeater { model: positionPluginRoot.crossSliderKeys; delegate: sliderDelegate }
                            }
                        }
                    }
                }
            }

            // Footer
            RowLayout {
                Layout.fillWidth: true; Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 0; 
                Layout.bottomMargin: 5; spacing: 20
                Button {
                    text: positionPluginRoot.tr("reset")
                    onClicked: {
                        themeSettings.jsonColors = "{}";
                        Theme.applyColors(positionPluginRoot.defaultColors);
                        var keys = Object.keys(positionPluginRoot.defaultColors);
                        for(var i=0; i<keys.length; i++) {
                            positionPluginRoot.updateLiveMarker(keys[i], positionPluginRoot.defaultColors[keys[i]]);
                            positionPluginRoot.updateCrosshair(keys[i], positionPluginRoot.defaultColors[keys[i]]);
                        }
                    }
                }
                Button {
                    text: positionPluginRoot.tr("apply")
                    highlighted: true
                    onClicked: positionColorDialog.close()
                }
            }
        }
    }

    // --- COMPOSANTS ---
    Component {
        id: colorDelegate
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            color: "#259E9E9E" 
            border.color: Theme.controlBorderColor; border.width: 1; radius: 6
            property string key: modelData
            property var conf: positionPluginRoot.positionColorConfig[key]
            property var val: positionPluginRoot.getCurrentValue(key)

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
                    // L'ICONE EST RESTAURÉE ICI
                    icon.source: "palette_icon.svg"
                    icon.color: Theme.mainTextColor
                    icon.width: 24; icon.height: 24
                    Layout.preferredWidth: 40; Layout.preferredHeight: 40
                    background: Rectangle { color: parent.down ? Theme.controlBackgroundColor : "transparent"; radius: 4 }
                    onClicked: colorPicker.open()
                }
            }
            ColorDialog {
                id: colorPicker
                title: conf.name
                selectedColor: val 
                onAccepted: positionPluginRoot.applyChange(key, "" + selectedColor)
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
            property var conf: positionPluginRoot.positionColorConfig[key]
            property var val: Number(positionPluginRoot.getCurrentValue(key))

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
                    onMoved: positionPluginRoot.applyChange(key, value)
                }
            }
        }
    }

    Timer {
        id: loadTimer
        interval: 1000
        running: true
        onTriggered: {
            try {
                var c = JSON.parse(themeSettings.jsonColors || "{}");
                var keys = Object.keys(c);
                if(keys.length > 0) {
                    Theme.applyColors(c);
                    for (var i = 0; i < keys.length; i++) {
                        positionPluginRoot.updateLiveMarker(keys[i], c[keys[i]]);
                        positionPluginRoot.updateCrosshair(keys[i], c[keys[i]]);
                    }
                } else {
                    var defKeys = Object.keys(positionPluginRoot.defaultColors);
                    for (var j = 0; j < defKeys.length; j++) {
                       if (defKeys[j].indexOf("crosshair") !== -1)
                           positionPluginRoot.updateCrosshair(defKeys[j], positionPluginRoot.defaultColors[defKeys[j]]);
                    }
                }
            } catch(e) {}
        }
    }
}