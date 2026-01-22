import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Theme
import org.qfield
import org.qgis

Item {
    id: filterToolRoot

    // Propriétés globales
    property var mainWindow: iface.mainWindow()
    property var mapCanvas: iface.mapCanvas()
    property var selectedLayer: null
    property var featureFormItem: iface.findItemByObjectName("featureForm")

    // État du filtre
    property bool filterActive: false
    property bool isFormVisible: false

    // Persistance
    property bool showAllFeatures: false
    property bool showFeatureList: false
    property string savedLayerName: ""
    property string savedFieldName: ""
    property string savedFilterText: ""

    // Gestion des couleurs personnalisées
    property color targetFocusColor: "#D500F9"
    property color targetSelectedColor: "#23FF0A"
    property color origFocusColor: "#ff7777"
    property color origSelectedColor: Theme.mainColor
    property color origBaseColor: "yellow"
    property color origProjectColor: "yellow"
    property var highlightItem: null

    // Variables pour la liste des entités
    property var pendingFormLayer: null
    property string pendingFormExpr: ""

    // Initialisation
    Component.onCompleted: {
        updateLayers()
        if (featureFormItem) isFormVisible = featureFormItem.visible
        if (qgisProject) origProjectColor = qgisProject.selectionColor
        applyCustomColors()
    }

    // Fonctions de gestion des couleurs
    function findHighlighterRecursive(parentItem) {
        if (!parentItem) return null
        var kids = parentItem.data
        if (!kids) return null

        for (var i = 0; i < kids.length; i++) {
            var item = kids[i]
            if (item && item.hasOwnProperty("focusedColor") &&
                item.hasOwnProperty("selectedColor") &&
                item.hasOwnProperty("selectionModel")) {

                if (!item.hasOwnProperty("showSelectedOnly") || item.showSelectedOnly === false) {
                    highlightItem = item
                    origFocusColor = item.focusedColor
                    origSelectedColor = item.selectedColor
                    if (item.hasOwnProperty("color")) origBaseColor = item.color
                    return item
                }
            }
            if (item.data) {
                var found = findHighlighterRecursive(item)
                if (found) return found
            }
        }
        return null
    }

    function applyCustomColors() {
        if (!highlightItem) {
            var container = iface.findItemByObjectName("mapCanvasContainer")
            if (container) findHighlighterRecursive(container)
        }

        if (highlightItem) {
            highlightItem.focusedColor = targetFocusColor
            highlightItem.selectedColor = targetSelectedColor
            if (highlightItem.hasOwnProperty("color")) highlightItem.color = targetSelectedColor
        }

        if (qgisProject) {
            qgisProject.selectionColor = targetSelectedColor
        }

        if (mapCanvas) mapCanvas.refresh()
    }

    function restoreOriginalColors() {
        if (highlightItem) {
            highlightItem.focusedColor = origFocusColor
            highlightItem.selectedColor = origSelectedColor
            if (highlightItem.hasOwnProperty("color")) highlightItem.color = origBaseColor
        }

        if (qgisProject) {
            qgisProject.selectionColor = origProjectColor
        }

        if (mapCanvas) mapCanvas.refresh()
    }

    // Timers
    Timer {
        id: zoomTimer
        interval: 200
        repeat: false
        onTriggered: performZoom()
    }

    Timer {
        id: searchDelayTimer
        interval: 500
        repeat: false
        onTriggered: performDynamicSearch()
    }

    Timer {
        id: openListTimer
        interval: 250
        repeat: false
        onTriggered: {
            if (featureFormItem && pendingFormLayer && pendingFormExpr && pendingFormExpr !== "") {
                try {
                    // Configuration du modèle avec les nouvelles données
                    featureFormItem.model.setFeatures(pendingFormLayer, pendingFormExpr)

                    // Activation de l'auto-zoom
                    if (featureFormItem.extentController) {
                        featureFormItem.extentController.autoZoom = true
                    }

                    // Affichage du FeatureForm
                    featureFormItem.show()

                    // Réinitialisation des variables temporaires
                    pendingFormLayer = null
                    pendingFormExpr = ""
                } catch(e) {
                    console.warn("Erreur lors de l'ouverture de la liste: ", e)
                    pendingFormLayer = null
                    pendingFormExpr = ""
                }
            }
        }
    }

    // Fonctions publiques
    function openFilterUI() {
        if (!filterActive) {
            showAllFeatures = false
            showFeatureList = false  // Réinitialisation de la checkbox
            showListCheck.checked = false  // Réinitialisation visuelle
            savedLayerName = ""
            savedFieldName = ""
            savedFilterText = ""
            if(valueField) valueField.text = ""
            selectedLayer = null
            pendingFormLayer = null
            pendingFormExpr = ""
        } else {
            if(valueField) valueField.text = savedFilterText
        }
        updateLayers()
        searchDialog.open()
    }

    function removeAllFilters() {
    restoreOriginalColors()

    var layers = ProjectUtils.mapLayers(qgisProject)
    for (var id in layers) {
        var pl = layers[id]
        if (pl && pl.type === 0) {
            try {
                pl.subsetString = ""
                pl.removeSelection()
                pl.triggerRepaint()
            } catch (_) {}
        }
    }

    // Fermeture PROPRE du FeatureForm en simulant un appui sur "back"
    if (featureFormItem) {
        // Utilisation de la méthode state pour simuler le comportement back
        featureFormItem.state = "Hidden"

        // Réinitialisation de la checkbox
        showFeatureList = false
        showListCheck.checked = false
    }

    // Réinitialisation des variables
    filterActive = false
    showAllFeatures = false
    savedLayerName = ""
    savedFieldName = ""
    savedFilterText = ""
    pendingFormLayer = null
    pendingFormExpr = ""

    if(valueField) {
        valueField.text = ""
        valueField.model = []
    }

    selectedLayer = null
    mapCanvas.refresh()
    updateLayers()
    updateApplyState()
    mainWindow.displayToast(tr("Filter deleted"))
}

    // Gestion des événements
    Connections {
        target: featureFormItem
        function onVisibleChanged() {
            filterToolRoot.isFormVisible = featureFormItem.visible
            if (!featureFormItem.visible) {
                if (filterActive) {
                    refreshVisualsOnly()
                }
            }
        }
    }

    // Gestion de la sélection depuis la liste des entités
    Connections {
        target: featureFormItem
        function onFeatureSelected(feature) {
            if (feature && selectedLayer) {
                selectedLayer.removeSelection()
                selectedLayer.select(feature.id())
                applyCustomColors()
                zoomTimer.start()
            }
        }
    }

    // Traduction
    function tr(text) {
        var isFrench = Qt.locale().name.substring(0, 2) === "fr"
        var dictionary = {
            "Filter deleted": "Filtre supprimé", "FILTER": "FILTRE",
            "Select a layer": "Sélectionnez une couche", "Select a field": "Sélectionnez un champ",
            "Filter value(s) (separate by ;) :": "Valeur(s) du filtre (séparer par ;) :",
            "Show all geometries (+filtered)": "Afficher toutes géométries (+filtrées)",
            "Show feature list": "Afficher liste des entités", "Apply filter": "Appliquer le filtre",
            "Delete filter": "Supprimer le filtre", "Error fetching values: ": "Erreur récupération valeurs : ",
            "Error Zoom: ": "Erreur Zoom : ", "Error: ": "Erreur : ",
            "Searching...": "Recherche...", "Type to search (ex: Paris; Lyon)...": "Tapez pour rechercher (ex: Paris; Lyon)...",
            "Active Filter:": "Filtre Actif :"
        }
        return isFrench && dictionary[text] !== undefined ? dictionary[text] : text
    }

    // Bandeau d'information
    Rectangle {
        id: infoBanner
        parent: mapCanvas
        z: 9999; height: 32
        anchors.bottom: parent.bottom; anchors.bottomMargin: 60
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(bannerLayout.implicitWidth + 30, parent.width - 120)
        radius: 16; color: "#B3333333"; border.width: 0
        visible: filterToolRoot.filterActive && !filterToolRoot.isFormVisible

        RowLayout {
            id: bannerLayout
            anchors.fill: parent; anchors.leftMargin: 15; anchors.rightMargin: 15
            spacing: 10
            Rectangle {
                width: 8; height: 8; radius: 4
                color: targetSelectedColor
                Layout.alignment: Qt.AlignVCenter
            }
            Item {
                id: clipContainer
                Layout.preferredWidth: bannerText.contentWidth
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                Text {
                    id: bannerText
                    text: {
                        var val = filterToolRoot.savedFilterText.trim()
                        if (val.endsWith(";")) val = val.substring(0, val.length - 1).trim()
                        return filterToolRoot.savedLayerName + " | " + filterToolRoot.savedFieldName + " : " + val
                    }
                    color: "white"; font.bold: true; font.pixelSize: 13
                    wrapMode: Text.NoWrap; horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter; anchors.verticalCenter: parent.verticalCenter
                    x: 0
                    SequentialAnimation on x {
                        running: clipContainer && bannerText.contentWidth > clipContainer.width && infoBanner.visible
                        loops: Animation.Infinite
                        PauseAnimation { duration: 2000 }
                        NumberAnimation {
                            to: (clipContainer ? clipContainer.width : 0) - bannerText.contentWidth
                            duration: Math.max(0, (bannerText.contentWidth - (clipContainer ? clipContainer.width : 0)) * 20 + 2000)
                            easing.type: Easing.InOutQuad
                        }
                        PauseAnimation { duration: 1000 }
                        NumberAnimation {
                            to: 0
                            duration: Math.max(0, (bannerText.contentWidth - (clipContainer ? clipContainer.width : 0)) * 20 + 2000)
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }
        }
    }

    // Dialogue de recherche
    Dialog {
        id: searchDialog
        parent: mainWindow.contentItem
        modal: true; width: Math.min(450, mainWindow.width * 0.90)
        height: mainCol.implicitHeight + 30
        x: (parent.width - width) / 2
        y: {
            var centerPos = (parent.height - height) / 2
            var isPortrait = parent.height > parent.width
            var offset = isPortrait ? (parent.height * 0.10) : 0
            return centerPos - offset
        }
        background: Rectangle { color: "white"; border.color: "#80cc28"; border.width: 3; radius: 8 }
        MouseArea {
            anchors.fill: parent; z: -1; propagateComposedEvents: true
            onClicked: {
                if (valueField.focus) { valueField.focus = false; suggestionPopup.close() }
                mouse.accepted = false
            }
        }
        ColumnLayout {
            id: mainCol
            anchors.fill: parent; anchors.margins: 8; spacing: 12
            Label {
                text: tr("FILTER"); font.bold: true; font.pointSize: 18; color: "black"
                horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true
                Layout.topMargin: -10; Layout.bottomMargin: 2
            }
            QfComboBox {
                id: layerSelector; Layout.fillWidth: true; Layout.preferredHeight: 35
                Layout.topMargin: -10; topPadding: 2; bottomPadding: 2; model: []
                onCurrentTextChanged: {
                    if (currentText === tr("Select a layer")) {
                        selectedLayer = null; fieldSelector.model = [tr("Select a field")]
                        fieldSelector.currentIndex = 0; valueField.model = []
                        updateApplyState(); return
                    }
                    selectedLayer = getLayerByName(currentText)
                    updateFields(); updateApplyState()
                }
            }
            QfComboBox {
                id: fieldSelector; Layout.fillWidth: true; Layout.preferredHeight: 35
                topPadding: 2; bottomPadding: 2; model: []
                onActivated: { valueField.text = ""; valueField.model = []; updateApplyState() }
                onCurrentTextChanged: updateApplyState()
            }
            Label {
                text: tr("Filter value(s) (separate by ;) :")
                Layout.topMargin: -8; Layout.bottomMargin: -10
            }
            TextField {
                id: valueField; Layout.fillWidth: true; Layout.preferredHeight: 35
                topPadding: 6; bottomPadding: 6
                placeholderText: tr("Type to search (ex: Paris; Lyon)...")
                Layout.bottomMargin: 2
                property var model: []; property bool isLoading: false
                onActiveFocusChanged: {
                    if (activeFocus) {
                        var parts = text.split(";")
                        var lastPart = parts[parts.length - 1].trim()
                        if (lastPart.length > 0) {
                            if (model.length > 0) suggestionPopup.open()
                            else performDynamicSearch()
                        }
                    }
                }
                onTextEdited: {
                    var parts = text.split(";")
                    var lastPart = parts[parts.length - 1].trim()
                    if (lastPart.length > 0) searchDelayTimer.restart()
                    else { searchDelayTimer.stop(); suggestionPopup.close(); model = [] }
                    updateApplyState()
                }
                onTextChanged: updateApplyState()
                onAccepted: { suggestionPopup.close(); updateApplyState() }
                BusyIndicator {
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 5; height: parent.height * 0.6; width: height
                    running: valueField.isLoading; visible: valueField.isLoading
                }
                Popup {
                    id: suggestionPopup; y: valueField.height; width: valueField.width
                    height: Math.min(listView.contentHeight + 10, 200); padding: 1
                    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
                    background: Rectangle { color: "white"; border.color: "#bdbdbd"; radius: 2 }
                    ListView {
                        id: listView; anchors.fill: parent; clip: true; model: valueField.model
                        delegate: ItemDelegate {
                            text: modelData; width: listView.width
                            background: Rectangle { color: parent.highlighted ? "#e0e0e0" : "transparent" }
                            onClicked: {
                                var currentText = valueField.text; var lastSep = currentText.lastIndexOf(";")
                                var newText = lastSep === -1 ? modelData + " ; " :
                                              currentText.substring(0, lastSep + 1) + " " + modelData + " ; "
                                valueField.text = newText; suggestionPopup.close()
                                valueField.forceActiveFocus(); valueField.model = []
                            }
                        }
                    }
                }
            }
            CheckBox {
                id: showAllCheck
                text: tr("Show all geometries (+filtered)")
                checked: showAllFeatures
                Layout.fillWidth: true
                Layout.topMargin: -12
                Layout.bottomMargin: -12
                onToggled: {
                    showAllFeatures = checked
                    if (filterActive) applyFilter(true, false)
                }
            }
            CheckBox {
                id: showListCheck
                text: tr("Show feature list")
                checked: showFeatureList
                Layout.fillWidth: true
                Layout.topMargin: -12
                Layout.bottomMargin: -16
                onToggled: {
                    showFeatureList = checked
                    if (filterActive) {
                        if (checked) {
                            applyFilter(true, false)
                        }
                        // NE PAS FERMER LA LISTE ICI - on laisse l'utilisateur le faire manuellement
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 5; Layout.bottomMargin: 2
                Button {
                    id: applyButton
                    text: tr("Apply filter")
                    enabled: false
                    Layout.fillWidth: true
                    background: Rectangle { color: "#80cc28"; radius: 10 }
                    onClicked: {
                        applyFilter(true, true)
                        searchDialog.close()
                    }
                }
                Button {
                    text: tr("Delete filter")
                    Layout.fillWidth: true
                    background: Rectangle { color: "#333333"; radius: 10 }
                    contentItem: Text {
                        text: tr("Delete filter")
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        removeAllFilters()
                        searchDialog.close()
                    }
                }
            }
        }
    }

    // Logique métier
    function updateLayers() {
        var layers = ProjectUtils.mapLayers(qgisProject)
        var names = []
        for (var id in layers)
            if (layers[id] && layers[id].type === 0)
                names.push(layers[id].name)
        names.sort()
        if (!filterActive) names.unshift(tr("Select a layer"))
        if (layerSelector) {
            layerSelector.model = names
            if (filterActive && savedLayerName !== "") {
                var idx = names.indexOf(savedLayerName)
                layerSelector.currentIndex = idx >= 0 ? idx : 0
            } else {
                layerSelector.currentIndex = 0
            }
        }
    }

    function getLayerByName(name) {
        var layers = ProjectUtils.mapLayers(qgisProject)
        for (var id in layers) if (layers[id].name === name) return layers[id]
        return null
    }

    function getFields(layer) {
        if (!layer || !layer.fields) return []
        var fields = layer.fields
        return fields.names ? fields.names.slice().sort() : []
    }

    function updateFields() {
        if (!selectedLayer) {
            fieldSelector.model = [tr("Select a field")]
            fieldSelector.currentIndex = 0
            return
        }
        var fields = getFields(selectedLayer)
        if (!filterActive) fields.unshift(tr("Select a field"))
        fieldSelector.model = fields
        if (filterActive && savedFieldName !== "") {
            var idx = fields.indexOf(savedFieldName)
            fieldSelector.currentIndex = idx >= 0 ? idx : 0
        } else {
            fieldSelector.currentIndex = 0
            valueField.model = []
        }
        updateApplyState()
    }

    function performDynamicSearch() {
        var rawText = valueField.text
        var parts = rawText.split(";")
        var lastPart = parts[parts.length - 1]
        var searchText = lastPart.trim()
        var uiName = fieldSelector.currentText

        if (!selectedLayer || uiName === tr("Select a field") || searchText === "") {
            valueField.model = []
            suggestionPopup.close()
            return
        }

        valueField.isLoading = true

        var names = selectedLayer.fields.names
        var logicalIndex = -1
        for (var i = 0; i < names.length; i++) {
            if (names[i] === uiName) {
                logicalIndex = i
                break
            }
        }
        if (logicalIndex === -1) {
            valueField.isLoading = false
            return
        }

        var realIndex = -1
        var attributes = selectedLayer.attributeList()
        if (attributes && logicalIndex < attributes.length) realIndex = attributes[logicalIndex]
        else realIndex = logicalIndex + 1

        var uniqueValues = {}
        var valuesArray = []

        try {
            var escapedText = searchText.replace(/'/g, "''")
            var expression = "\"" + uiName + "\" ILIKE '%" + escapedText + "%'"

            var feature_iterator = LayerUtils.createFeatureIteratorFromExpression(selectedLayer, expression)

            var count = 0
            var max_display_items = 50
            var safety_counter = 0
            var max_scan = 5000

            while (feature_iterator.hasNext() && count < max_display_items && safety_counter < max_scan) {
                var feature = feature_iterator.next()
                var val = feature.attribute(realIndex)
                if (val === undefined) val = feature.attribute(uiName)

                if (val !== null && val !== undefined) {
                    var strVal = String(val).trim()
                    if (strVal !== "" && strVal !== "NULL") {
                        var alreadyInText = false
                        for(var p=0; p<parts.length-1; p++) {
                            if (parts[p].trim() === strVal) {
                                alreadyInText = true
                                break
                            }
                        }

                        if (!uniqueValues[strVal] && !alreadyInText) {
                            uniqueValues[strVal] = true
                            valuesArray.push(strVal)
                            count++
                        }
                    }
                }
                safety_counter++
            }

            valuesArray.sort()
            valueField.model = valuesArray

            if (valuesArray.length > 0) {
                suggestionPopup.open()
            } else {
                suggestionPopup.close()
            }

        } catch (e) {
            console.log("Error searching: " + e)
        }

        valueField.isLoading = false
    }

    function updateApplyState() {
        if(applyButton && selectedLayer && fieldSelector && valueField) {
            applyButton.enabled = selectedLayer !== null &&
                                fieldSelector.currentText &&
                                fieldSelector.currentText !== tr("Select a field") &&
                                valueField.text.length > 0
        }
    }

    function escapeValue(value) {
        return value.trim().replace(/'/g, "''")
    }

    // Fonction ZOOM améliorée
    function performZoom() {
        if (!selectedLayer) return

        var bbox = selectedLayer.boundingBoxOfSelected()
        if (!bbox || bbox.width === 0 || bbox.height === 0) {
            var selectedFeatures = selectedLayer.selectedFeatures()
            if (selectedFeatures.length > 0) {
                bbox = selectedFeatures[0].geometry().boundingBox()
            }
        }

        if (!bbox || bbox.width === 0 || bbox.height === 0) {
            console.warn("Impossible de zoomer: bounding box invalide")
            return
        }

        try {
            var reprojectedExtent = GeometryUtils.reprojectRectangle(
                bbox,
                selectedLayer.crs,
                mapCanvas.mapSettings.destinationCrs
            )

            if (!reprojectedExtent || reprojectedExtent.width === 0 || reprojectedExtent.height === 0) {
                console.warn("Étendue reprojetée invalide")
                return
            }

            var centerX = reprojectedExtent.xMinimum + (reprojectedExtent.width / 2.0)
            var centerY = reprojectedExtent.yMinimum + (reprojectedExtent.height / 2.0)
            var isPoint = (reprojectedExtent.width < 0.00001 && reprojectedExtent.height < 0.00001)

            if (isPoint) {
                var buffer = 0.002
                reprojectedExtent.xMinimum = centerX - buffer
                reprojectedExtent.xMaximum = centerX + buffer
                reprojectedExtent.yMinimum = centerY - buffer
                reprojectedExtent.yMaximum = centerY + buffer
            } else {
                var currentMapExtent = mapCanvas.mapSettings.extent
                var screenRatio = currentMapExtent.width / currentMapExtent.height
                var geomRatio = reprojectedExtent.width / reprojectedExtent.height
                var marginScale = 1.1

                var newWidth = 0
                var newHeight = 0

                if (geomRatio > screenRatio) {
                    newWidth = reprojectedExtent.width * marginScale
                    newHeight = newWidth / screenRatio
                } else {
                    newHeight = reprojectedExtent.height * marginScale
                    newWidth = newHeight * screenRatio
                }

                reprojectedExtent.xMinimum = centerX - (newWidth / 2.0)
                reprojectedExtent.xMaximum = centerX + (newWidth / 2.0)
                reprojectedExtent.yMinimum = centerY - (newHeight / 2.0)
                reprojectedExtent.yMaximum = centerY + (newHeight / 2.0)
            }

            mapCanvas.mapSettings.setExtent(reprojectedExtent, true)
            mapCanvas.refresh()
            applyCustomColors()

        } catch(e) {
            console.error("Erreur lors du zoom: ", e)
            mainWindow.displayToast(tr("Erreur lors du zoom: ") + e)
        }
    }

    function refreshVisualsOnly() {
        if (selectedLayer) {
            mapCanvas.mapSettings.selectionColor = targetSelectedColor
            selectedLayer.triggerRepaint()
            mapCanvas.refresh()
        }
    }

    function applyFilter(allowFormOpen, doZoom) {
        if (!selectedLayer || !fieldSelector.currentText || !valueField.text) return
        if (allowFormOpen === undefined) allowFormOpen = true
        if (doZoom === undefined) doZoom = true

        try {
            savedLayerName = layerSelector.currentText
            savedFieldName = fieldSelector.currentText
            savedFilterText = valueField.text

            var fieldName = savedFieldName
            var values = savedFilterText.split(";").map(function(v) {
                return escapeValue(v.toLowerCase().trim())
            }).filter(function(v) {
                return v.length > 0
            })

            if (values.length === 0) return

            var expr = values.map(function(v) {
                return 'lower("' + fieldName + '") LIKE \'%' + v + '%\''
            }).join(" OR ")

            if (showAllFeatures) selectedLayer.subsetString = ""
            else selectedLayer.subsetString = expr

            selectedLayer.removeSelection()
            mapCanvas.mapSettings.selectionColor = targetSelectedColor
            selectedLayer.selectByExpression(expr)

            selectedLayer.triggerRepaint()
            mapCanvas.refresh()

            if (showFeatureList && featureFormItem && selectedLayer === getLayerByName(savedLayerName)) {
                pendingFormLayer = selectedLayer
                pendingFormExpr = expr
                openListTimer.restart()
            }
            // NE PAS FERMER LA LISTE ICI - on laisse l'utilisateur le faire manuellement

            if (doZoom) {
                zoomTimer.start()
            }
            filterActive = true

        } catch(e) {
            mainWindow.displayToast(tr("Error: ") + e)
        }
    }
}