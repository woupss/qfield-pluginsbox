import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import org.qfield
import org.qgis
import Theme
import "."
import "plugins"

Item {
    id: mainLauncher
    property var mainWindow: iface.mainWindow()
    
    // Variable pour distinguer le clic du long press
    property bool wasLongPress: false

    // -----------------------------------------------------------
    // 0. SYSTEME DE TRADUCTION
    // -----------------------------------------------------------
    function tr(text) {
        var isFrench = Qt.locale().name.substring(0, 2) === "fr"
        
        var dictionary = {
            // Titres et labels
            "Plugin Box": "Boîte à plugins",
            "Tip: Long press": "Astuce : Appui long sur l'icône du plugin\npour supprimer tous les filtres.",
            
            // Boutons (avec Emojis)
            "FILTERS": "🔍 FILTRES",
            "Customize Position": "🎨 Personnaliser Position",
            "Update .qgz": "🔄 Mise à jour .qgz",
            "Manage Plugins": "🛠️ Gérer les Plugins", // NOUVEAU LIBELLE
            
            // Messages Toast
            "Filters cleared": "Filtres supprimés"
        }
        
        if (isFrench && dictionary[text] !== undefined) return dictionary[text]
        
        // Fallback Anglais
        if (text === "FILTERS") return "🔍 FILTERS"
        if (text === "Customize Position") return "🎨 Customize Position"
        if (text === "Update .qgz") return "🔄 Update .qgz"
        if (text === "Manage Plugins") return "🛠️ Manage Plugins"
        
        return text 
    }

    // -----------------------------------------------------------
    // 1. INSTANCIATION DES PLUGINS ENFANTS
    // -----------------------------------------------------------
    
    PositionSettings {
        id: positionTool
    }

    FilterTool {
        id: filterTool
    }
    
    // --- REMPLACEMENT ICI : PluginUpdateTool remplace DeleteTool ---
    PluginUpdateTool {
        id: pluginUpdateTool
    }

    UpdateTool {
        id: updateTool
    }

    // -----------------------------------------------------------
    // 2. LOGIQUE DU LONG PRESS (TIMER)
    // -----------------------------------------------------------
    Timer {
        id: longPressTimer
        interval: 800
        repeat: false
        onTriggered: {
            mainLauncher.wasLongPress = true
            filterTool.removeAllFilters()
            launcherBtn.opacity = 0.5
            mainWindow.displayToast(tr("Filters cleared"))
            restoreOpacityTimer.start()
        }
    }

    Timer {
        id: restoreOpacityTimer
        interval: 200
        onTriggered: launcherBtn.opacity = 1.0
    }

    // -----------------------------------------------------------
    // 3. INTERFACE UTILISATEUR (BOUTON & MENU)
    // -----------------------------------------------------------

    QfToolButton {
        id: launcherBtn
        iconSource: 'icon.svg'
        iconColor: Theme.mainColor
        bgcolor: Theme.darkGray
        round: true
        
        onPressed: {
            mainLauncher.wasLongPress = false
            longPressTimer.start()
        }
        
        onReleased: {
            if (longPressTimer.running) {
                longPressTimer.stop()
                launcherDialog.open()
            }
        }
    }

    Dialog {
        id: launcherDialog
        modal: true
        visible: false
        parent: mainLauncher.mainWindow.contentItem
        anchors.centerIn: parent
        width: Math.min(300, parent.width * 0.8)
        
        background: Rectangle {
            color: Theme.mainBackgroundColor
            radius: 8
            border.color: Theme.mainColor
            border.width: 2
        }

        contentItem: ColumnLayout {
            spacing: 15
            Layout.margins: 15 

            Label {
                text: tr("Plugin Box")
                font.bold: true
                font.pixelSize: 18
                color: Theme.mainTextColor
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 10
            }

            // --- BOUTON 1 : FILTRES ---
            Button {
                text: tr("FILTERS")
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                font.bold: true
                onClicked: {
                    launcherDialog.close()
                    filterTool.openFilterUI()
                }
            }

            // --- BOUTON 2 : POSITION ---
            Button {
                text: tr("Customize Position")
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                font.bold: true
                onClicked: {
                    launcherDialog.close()
                    positionTool.openSettings()
                }
            }
            
            // --- BOUTON 3 : MISE A JOUR PROJET ---
            Button {
                text: tr("Update .qgz")
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                font.bold: true
                contentItem: Text { 
                    text: parent.text
                    color: "#1976D2" // Bleu 
                    font: parent.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    launcherDialog.close()
                    updateTool.openUpdateUI()
                }
            }

            // --- BOUTON 4 : MISE A JOUR DES PLUGINS (Remplacement) ---
            Button {
                text: tr("Manage Plugins")
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                font.bold: true
                contentItem: Text { 
                    text: parent.text
                    color: "#D32F2F" // Conserve le rouge pour le style
                    font: parent.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    launcherDialog.close()
                    // Appel de la nouvelle fonction du plugin annexe
                    pluginUpdateTool.openPluginUpdateUI()
                }
            }
            
            // Petit texte d'aide
            Label {
                text: tr("Tip: Long press on plugin icon to delete all filters")
                color: Theme.secondaryTextColor
                font.pixelSize: 10
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                Layout.topMargin: 10
                Layout.bottomMargin: 5
            }
        }
    }

    Component.onCompleted: {
        iface.addItemToPluginsToolbar(launcherBtn);
    }
}