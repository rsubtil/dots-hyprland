pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool customMode: false
    property var hidden: []
    property var renamed: ({})

    function isHidden(id) {
        if (!root.customMode) return false;
        return root.hidden.indexOf(id) !== -1;
    }

    function resolveName(id, defaultName) {
        if (root.renamed && root.renamed[id] !== undefined && root.renamed[id] !== "")
            return root.renamed[id];
        return defaultName;
    }

    function setHidden(id, hide) {
        let arr = root.hidden.slice();
        const idx = arr.indexOf(id);
        if (hide && idx === -1) {
            arr.push(id);
        } else if (!hide && idx !== -1) {
            arr.splice(idx, 1);
        }
        root.hidden = arr;
        saveToFile();
    }

    function setRenamed(id, name) {
        let obj = Object.assign({}, root.renamed);
        if (name === "" || name === null || name === undefined) {
            delete obj[id];
        } else {
            obj[id] = name;
        }
        root.renamed = obj;
        saveToFile();
    }

    function saveToFile() {
        const data = {
            mode: root.customMode ? "custom" : "all",
            hidden: root.hidden,
            renamed: root.renamed
        };
        appsConfigFile.setText(JSON.stringify(data, null, 2));
    }

    FileView {
        id: appsConfigFile
        path: Directories.appsConfigPath
        watchChanges: true
        onFileChanged: appsConfigFile.reload()
        onLoaded: {
            const text = appsConfigFile.text();
            if (!text || text.trim() === "") return;
            try {
                const data = JSON.parse(text);
                root.customMode = (data.mode === "custom");
                root.hidden = Array.isArray(data.hidden) ? data.hidden : [];
                root.renamed = (data.renamed && typeof data.renamed === "object") ? data.renamed : ({});
            } catch (e) {
                // Malformed JSON — keep defaults
            }
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.saveToFile();
            }
        }
    }

    Component.onCompleted: {
        appsConfigFile.reload();
    }
}
