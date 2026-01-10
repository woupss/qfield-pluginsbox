import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Theme
import org.qfield
import org.qgis
import QtCore

Item {
    id: updateToolRoot
    property var mainWindow: iface.mainWindow()
    property string fullDestinationPath: ""
    property bool isSuccess: false
    property bool isNameMismatch: false

    // =========================================================================
    // 0. FONCTION DE RECHARGEMENT
    // =========================================================================
    
    function triggerReload() {
        downloadDialog.close()
        
        if (fullDestinationPath === qgisProject.fileName) {
            iface.reloadProject()
        } else {
            iface.openProject(fullDestinationPath)
        }
    }

    // =========================================================================
    // 1. GESTION DES TRADUCTIONS
    // =========================================================================

    property var translations: {
        "fr": {
            "TITLE": "MISE À JOUR",
            "LBL_SOURCE": "URL source :",
            "PH_URL": "https://github.com/User/Repo/blob/main/projet.qgz",
            "CB_TOKEN": "Utiliser un token privé (GitHub PAT)",
            "PH_TOKEN": "ghp_xxxxxxxxxxxx...",
            "LBL_TARGET": "Nom du fichier cible :",
            "WARN_REPLACE": "Le projet actuel sera remplacé.",
            "WARN_MISMATCH": "Le fichier de l'URL est différent du projet ouvert.",
            "CB_ALLOW_DIFF": "Je confirme vouloir enregistrer sous un autre nom",
            "LBL_PATH": "Dossier de destination :",
            "BTN_CLOSE": "Fermer",
            "BTN_RELOAD": "Recharger le projet",
            "BTN_UPDATE_SAME": "Mettre à jour le projet",
            "BTN_UPDATE_DIFF": "Télécharger une version différente",
            "STATUS_READY": "Prêt.",
            "STATUS_DOWNLOADING": "Téléchargement en cours...",
            "STATUS_WRITING": "Écriture sur le disque...",
            "STATUS_SUCCESS": "SUCCÈS",
            "STATUS_ERR_WRITE": "Erreur d'écriture.",
            "TOAST_URL_EMPTY": "L'URL est vide !",
            "TOAST_FILENAME_INVALID": "Nom de fichier invalide !",
            "TOAST_WRITE_FAILED": "Échec de l'écriture",
            "INFO_ACTION": "⚠️ TÉLÉCHARGEMENT RÉUSSI :\nCliquez sur 'Recharger le projet' pour appliquer les modifications.",
            "ERR_FILENAME_DETECT": "Erreur : Nom de fichier indéterminé.",
            "ERR_NOT_FOUND": " (404 Introuvable)\nVérifiez l'URL, la branche ou les droits du token.",
            "ERR_AUTH": " (401 Non autorisé)\nVérifiez votre Token.",
            "ERR_API_CONVERT": "Impossible de convertir l'URL au format API."
        },
        "en": {
            "TITLE": "UPDATE",
            "LBL_SOURCE": "Source URL:",
            "PH_URL": "https://github.com/User/Repo/blob/main/project.qgz",
            "CB_TOKEN": "Use private token (GitHub PAT)",
            "PH_TOKEN": "ghp_xxxxxxxxxxxx...",
            "LBL_TARGET": "Target filename:",
            "WARN_REPLACE": "The current project will be replaced.",
            "WARN_MISMATCH": "URL filename differs from open project.",
            "CB_ALLOW_DIFF": "I confirm saving with a different name",
            "LBL_PATH": "Destination folder:",
            "BTN_CLOSE": "Close",
            "BTN_RELOAD": "Reload Project",
            "BTN_UPDATE_SAME": "Update Project",
            "BTN_UPDATE_DIFF": "Download different version",
            "STATUS_READY": "Ready.",
            "STATUS_DOWNLOADING": "Downloading...",
            "STATUS_WRITING": "Writing to disk...",
            "STATUS_SUCCESS": "SUCCESS",
            "STATUS_ERR_WRITE": "Write error.",
            "TOAST_URL_EMPTY": "URL is empty!",
            "TOAST_FILENAME_INVALID": "Filename is invalid!",
            "TOAST_WRITE_FAILED": "Write failed",
            "INFO_ACTION": "⚠️ DOWNLOAD SUCCESSFUL:\nClick 'Reload Project' to apply changes.",
            "ERR_FILENAME_DETECT": "Error: Could not determine filename.",
            "ERR_NOT_FOUND": " (404 Not Found)\nCheck URL, branch or token permissions.",
            "ERR_AUTH": " (401 Unauthorized)\nCheck your Token.",
            "ERR_API_CONVERT": "Could not convert URL to API format."
        }
    }

    function tr(key) {
        var dict = translations["en"];
        var sysLang = Qt.locale().name;
        if (sysLang.substring(0, 2) === "fr") {
            dict = translations["fr"];
        }
        var val = dict[key];
        return val !== undefined ? val : key;
    }

    // =========================================================================
    // 2. COMPOSANT PERSONNALISÉ : MARQUEE TEXT FIELD
    // =========================================================================
    
    component MarqueeTextField : TextField {
        id: control
        property color normalColor: "black"
        color: activeFocus ? normalColor : "transparent"
        clip: true 
        Layout.preferredHeight: Math.max(40, contentHeight + topPadding + bottomPadding + 15)
        verticalAlignment: TextInput.AlignVCenter

        Item {
            id: marqueeContainer
            anchors.fill: parent
            anchors.leftMargin: control.leftPadding
            anchors.rightMargin: control.rightPadding
            anchors.topMargin: control.topPadding
            anchors.bottomMargin: control.bottomPadding
            visible: !control.activeFocus 
            clip: true

            Text {
                id: scrollingText
                text: control.text
                font: control.font
                color: control.normalColor
                verticalAlignment: Text.AlignVCenter
                height: parent.height
                x: 0
                property bool needsScroll: width > marqueeContainer.width
                property int travelDistance: Math.max(0, width - marqueeContainer.width)

                SequentialAnimation on x {
                    running: scrollingText.needsScroll && marqueeContainer.visible
                    loops: Animation.Infinite
                    PauseAnimation { duration: 2000 }
                    NumberAnimation {
                        to: -scrollingText.travelDistance
                        duration: scrollingText.travelDistance > 0 ? scrollingText.travelDistance * 20 : 0
                        easing.type: Easing.Linear
                    }
                    PauseAnimation { duration: 1000 }
                    NumberAnimation {
                        to: 0
                        duration: scrollingText.travelDistance > 0 ? scrollingText.travelDistance * 20 : 0
                        easing.type: Easing.Linear
                    }
                }
            }
        }
    }

    // =========================================================================
    // 3. LOGIQUE METIER & INTERFACE PUBLIQUE
    // =========================================================================

    function openUpdateUI() {
        isSuccess = false
        statusText.text = tr("STATUS_READY")
        statusText.color = "black"
        infoBox.visible = false
        infoText.visible = false
        pBar.visible = false
        downloadBtn.enabled = true
        
        filenameInput.text = "" 
        urlInput.text = "" 
        allowDiffCheckbox.checked = false
        isNameMismatch = false
        
        useTokenCheckbox.checked = false
        tokenInput.text = ""
        
        downloadDialog.open()
        calculatePath(); 
    }

    function getCurrentProjectName() {
        var fullPath = qgisProject.fileName;
        if (!fullPath) return "";
        var parts = fullPath.split('/');
        return parts[parts.length - 1];
    }

    function extractNameFromUrl(url) {
        if (!url || url.trim() === "") return "";
        try {
            var cleanUrl = url.split('?')[0];
            var lower = cleanUrl.toLowerCase();
            if (lower.indexOf(".qgz") === -1 && lower.indexOf(".qgs") === -1) return "";
            var parts = cleanUrl.split('/');
            var name = parts[parts.length - 1];
            return name;
        } catch (e) {
            return "";
        }
    }

    // --- MODE SANS TOKEN (ORIGINAL) ---
    function getRawUrlOld(url) {
        var processed = url.trim();
        if (processed.indexOf("http") !== 0) processed = "https://" + processed;

        if (processed.indexOf("raw.githubusercontent.com") !== -1) return processed;
        if (processed.indexOf("github.com") === -1) return processed;

        var blobRegex = /^(https?:\/\/(?:www\.)?)github\.com\/([^\/]+\/[^\/]+)\/(?:blob|raw)\/([^\/]+)\/(.+)$/;
        var blobMatch = processed.match(blobRegex);
        if (blobMatch) {
            return "https://raw.githubusercontent.com/" + blobMatch[2] + "/" + blobMatch[3] + "/" + blobMatch[4];
        }
        
        var shortRegex = /^(https?:\/\/(?:www\.)?)github\.com\/([^\/]+\/[^\/]+)\/(.+)$/;
        var shortMatch = processed.match(shortRegex);
        if (shortMatch) {
             return "https://raw.githubusercontent.com/" + shortMatch[2] + "/main/" + shortMatch[3];
        }

        return processed;
    }

    // --- MODE AVEC TOKEN (NOUVEAU) ---
    function getApiUrl(url) {
        var processed = url.trim();
        if (processed.indexOf("http") !== 0) processed = "https://" + processed;
        
        var regex = /github\.com\/([^\/]+)\/([^\/]+)\/(?:blob|raw|tree)\/([^\/]+)\/(.+)/;
        var match = processed.match(regex);
        
        if (match) {
            var user = match[1];
            var repo = match[2];
            var branch = match[3];
            var path = match[4];
            return "https://api.github.com/repos/" + user + "/" + repo + "/contents/" + path + "?ref=" + branch;
        }
        
        var shortRegex = /github\.com\/([^\/]+)\/([^\/]+)\/(.+)/;
        var shortMatch = processed.match(shortRegex);
        if (shortMatch) {
            return "https://api.github.com/repos/" + shortMatch[1] + "/" + shortMatch[2] + "/contents/" + shortMatch[3] + "?ref=main";
        }
        
        return ""; 
    }

    function getCorrectedFileName() {
        var rawName = filenameInput.text.trim();
        if (rawName !== "") {
            var lower = rawName.toLowerCase();
            if (!lower.endsWith(".qgz") && !lower.endsWith(".qgs")) {
                return rawName + ".qgz";
            }
            return rawName;
        }
        var urlName = extractNameFromUrl(urlInput.text);
        if (urlName !== "") return urlName;
        return getCurrentProjectName();
    }

    function calculatePath() {
        platformUtilities.requestStoragePermission();
        
        var folder = qgisProject.homePath;
        if (!folder) {
            folder = "/storage/emulated/0/Android/data/ch.opengis.qfield/files/imported_projects";
        }

        var currentProjName = getCurrentProjectName();
        var urlName = extractNameFromUrl(urlInput.text);

        if (urlName !== "" && urlName !== filenameInput.text) {
             filenameInput.text = urlName;
        } else if (urlName === "" && filenameInput.text === "") {
             filenameInput.text = currentProjName;
        }

        var targetName = getCorrectedFileName();
        
        if (targetName !== currentProjName) {
            if (!isNameMismatch) {
                allowDiffCheckbox.checked = false;
            }
            isNameMismatch = true;
        } else {
            isNameMismatch = false;
            allowDiffCheckbox.checked = false;
        }

        var fileName = targetName === "" ? "[filename]" : targetName;
        fullDestinationPath = folder + "/" + fileName;
        pathDisplay.text = folder + "/"; 
    }

    function startDownload() {
        // [CORRECTION 1] Forcer la perte de focus pour valider l'input et cacher le clavier
        dummyFocus.forceActiveFocus();
        Qt.inputMethod.hide();

        calculatePath(); 
        var finalName = getCorrectedFileName();
        var rawInputUrl = urlInput.text.trim();

        if (rawInputUrl === "") {
            mainWindow.displayToast(tr("TOAST_URL_EMPTY"))
            return;
        }
        
        if (isNameMismatch && !allowDiffCheckbox.checked) {
            mainWindow.displayToast(tr("WARN_MISMATCH"))
            return;
        }

        var urlWithFile = rawInputUrl;
        if (urlWithFile.toLowerCase().indexOf(".qgz") === -1 && urlWithFile.toLowerCase().indexOf(".qgs") === -1) {
            if (!urlWithFile.endsWith("/")) urlWithFile += "/";
            urlWithFile += finalName;
        }

        var finalUrl = "";
        
        if (useTokenCheckbox.checked) {
            finalUrl = getApiUrl(urlWithFile);
            if (finalUrl === "") {
                mainWindow.displayToast(tr("ERR_API_CONVERT"));
                return;
            }
        } else {
            finalUrl = getRawUrlOld(urlWithFile);
        }

        console.log("Downloading URL: " + finalUrl);

        pBar.visible = true
        pBar.indeterminate = true
        statusText.text = tr("STATUS_DOWNLOADING")
        statusText.color = Theme.mainColor
        downloadBtn.enabled = false
        infoBox.visible = false
        infoText.visible = false

        var xhr = new XMLHttpRequest()
        xhr.open("GET", finalUrl)
        xhr.responseType = "arraybuffer"

        // --- GESTION TOKEN CORRIGÉE ---
        if (useTokenCheckbox.checked) {
            // [CORRECTION 2] Utilisation de replace au lieu de trim
            // Cela supprime tous les espaces, sauts de lignes, tabs (\s)
            var tkn = tokenInput.text.replace(/\s/g, "");
            
            // Console log pour debug
            console.log("Token used (clean): " + tkn); 
            
            if (tkn !== "") {
                xhr.setRequestHeader("Authorization", "Bearer " + tkn);
                xhr.setRequestHeader("Accept", "application/vnd.github.v3.raw");
            }
        }

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                pBar.visible = false
                downloadBtn.enabled = true
                
                if (xhr.status === 200 || xhr.status === 0) {
                    saveToDisk(xhr.response)
                } else {
                    var err = "HTTP Error: " + xhr.status
                    if (xhr.status === 404) err += tr("ERR_NOT_FOUND")
                    else if (xhr.status === 401 || xhr.status === 403) err += tr("ERR_AUTH")
                    statusText.text = err
                    statusText.color = "red"
                    mainWindow.displayToast(err)
                }
            }
        }
        xhr.send()
    }

    function saveToDisk(data) {
        try {
            statusText.text = tr("STATUS_WRITING")
            var success = FileUtils.writeFileContent(fullDestinationPath, data)

            if (success) {
                isSuccess = true 
                statusText.text = tr("STATUS_SUCCESS")
                statusText.color = "#80cc28"
                infoText.text = tr("INFO_ACTION")
                infoText.visible = true
                infoBox.visible = true
            } else {
                statusText.text = tr("STATUS_ERR_WRITE")
                statusText.color = "red"
                mainWindow.displayToast(tr("TOAST_WRITE_FAILED"))
            }
        } catch (e) {
            statusText.text = "Exception: " + e
            statusText.color = "red"
        }
    }

    // =========================================================================
    // 4. INTERFACE (DIALOGUE)
    // =========================================================================

    Dialog {
        id: downloadDialog
        parent: mainWindow.contentItem
        modal: true
        width: Math.min(360, mainWindow.width * 0.85)

        x: (parent.width - width) / 2
        y: ((parent.height - height) / 2) - (parent.height * 0.15)
        
        standardButtons: Dialog.NoButton
        
        background: Rectangle { 
            color: "white"
            border.color: Theme.mainColor
            border.width: 2
            radius: 8 
        }

        contentItem: Item {
            implicitHeight: mainCol.implicitHeight
            implicitWidth: mainCol.implicitWidth

            FocusScope {
                id: dummyFocus
                anchors.fill: parent
                z: -1
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    dummyFocus.forceActiveFocus()
                    Qt.inputMethod.hide()
                    calculatePath()
                }
            }

            ColumnLayout {
                id: mainCol
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.bottomMargin: 16
                anchors.topMargin: 0 
                
                spacing: 2 

                Label {
                    text: tr("TITLE")
                    font.bold: true
                    font.pointSize: 16
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 0
                    Layout.bottomMargin: 5
                }

                // --- URL INPUT ---
                Text { 
                    text: tr("LBL_SOURCE"); 
                    color: "#666"; 
                    font.pixelSize: 12 
                }
                
                MarqueeTextField {
                    id: urlInput
                    text: "" 
                    placeholderText: tr("PH_URL")
                    selectByMouse: true
                    Layout.fillWidth: true
                    // Empêcher la correction auto sur les URL
                    inputMethodHints: Qt.ImhUrlCharactersOnly | Qt.ImhNoAutoUppercase
                    onTextChanged: calculatePath()
                }

                // --- TOKEN CHECKBOX ---
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 5
                    spacing: 8
                    
                    CheckBox {
                        id: useTokenCheckbox
                        checked: false
                    }
                    Text {
                        text: tr("CB_TOKEN")
                        color: "#333"
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        MouseArea {
                            anchors.fill: parent
                            onClicked: useTokenCheckbox.checked = !useTokenCheckbox.checked
                        }
                    }
                }

                // --- TOKEN INPUT ---
                MarqueeTextField {
                    id: tokenInput
                    visible: useTokenCheckbox.checked
                    text: ""
                    placeholderText: tr("PH_TOKEN")
                    selectByMouse: true
                    echoMode: TextInput.Password 
                    Layout.fillWidth: true
                    Layout.topMargin: 0
                    
                    // [CORRECTION 3] Configuration cruciale pour les tokens
                    // Désactive prédiction, majuscule auto et correction auto
                    inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhSensitiveData | Qt.ImhNoAutoCorrect
                }

                // --- FILENAME INPUT ---
                Text { 
                    text: tr("LBL_TARGET"); 
                    color: "#666"; 
                    font.pixelSize: 12 
                    Layout.topMargin: 10 
                }
                
                MarqueeTextField {
                    id: filenameInput
                    text: "" 
                    placeholderText: getCurrentProjectName()
                    selectByMouse: true
                    Layout.fillWidth: true
                    onTextChanged: calculatePath()
                }
                
                // --- ALERTE & CHECKBOX ---
                ColumnLayout {
                    visible: isNameMismatch
                    Layout.fillWidth: true
                    spacing: 5
                    Layout.topMargin: 8
                    
                    Text {
                        text: tr("WARN_MISMATCH")
                        color: "#e67e22" 
                        font.bold: true
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        spacing: 8
                        CheckBox {
                            id: allowDiffCheckbox
                            checked: false
                        }
                        Text {
                            text: tr("CB_ALLOW_DIFF")
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            MouseArea {
                                anchors.fill: parent
                                onClicked: allowDiffCheckbox.checked = !allowDiffCheckbox.checked
                            }
                        }
                    }
                }

                // --- AVERTISSEMENT ---
                Text { 
                    visible: !isNameMismatch
                    text: tr("WARN_REPLACE")
                    color: "red"
                    font.italic: true
                    font.pixelSize: 12 
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    Layout.topMargin: 5 
                }
                
                // --- PATH DISPLAY ---
                Text { 
                    text: tr("LBL_PATH"); 
                    color: "#666"; 
                    font.pixelSize: 12 
                    Layout.topMargin: 10 
                }
                Text { 
                    id: pathDisplay
                    text: "..." 
                    font.bold: true
                    font.pixelSize: 12
                    color: "#000000"
                    wrapMode: Text.WrapAnywhere
                    Layout.fillWidth: true 
                }

                ProgressBar { 
                    id: pBar
                    Layout.fillWidth: true
                    visible: false
                    indeterminate: true 
                    Layout.topMargin: 5
                }
                
                Text { 
                    id: statusText
                    text: tr("STATUS_READY")
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    font.bold: true 
                }
                
                Rectangle {
                    id: infoBox
                    visible: false
                    color: "#f0f0f0" 
                    radius: 4
                    border.color: "#dcdcdc"
                    Layout.fillWidth: true
                    Layout.preferredHeight: infoText.contentHeight + 30 
                    Layout.topMargin: 10

                    Text { 
                        id: infoText
                        visible: parent.visible
                        text: ""
                        color: "#333333" 
                        font.pixelSize: 13 
                        font.bold: true 
                        wrapMode: Text.WordWrap 
                        width: parent.width - 20
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter 
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 5
                    spacing: 20
                    Layout.alignment: Qt.AlignHCenter
                    
                    Button {
                        id: downloadBtn
                        
                        text: isSuccess ? tr("BTN_RELOAD") : (isNameMismatch ? tr("BTN_UPDATE_DIFF") : tr("BTN_UPDATE_SAME"))
                        
                        Layout.preferredWidth: Math.max(220, contentItem.implicitWidth + 24)
                        
                        enabled: isSuccess ? true : (isNameMismatch ? allowDiffCheckbox.checked : true)
                        
                        background: Rectangle { 
                            color: isSuccess ? "#80cc28" : (parent.enabled ? Theme.mainColor : "#ccc")
                            radius: 4 
                        }
                        
                        contentItem: Text { 
                            text: parent.text
                            color: "white"
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter 
                        }
                        
                        onClicked: {
                            if (isSuccess) {
                                updateToolRoot.triggerReload()
                            } else {
                                startDownload()
                            }
                        }
                    }
                }
            }
        }
    }
}