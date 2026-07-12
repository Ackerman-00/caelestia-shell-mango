pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import Caelestia
import qs.config

// TODO: handle this better later

Item {
    id: model

    property alias visibleModel: _visibleModel
    property string activeLabel: ""
    property int activeIndex: -1
    property var _xkbMap: ({})
    property bool _notifiedLimit: false

    function start() {
        _xkbXmlBase.running = true;
        _queryActiveLayout.running = true;
    }

    function refresh() {
        _notifiedLimit = false;
        _queryActiveLayout.running = true;
    }

    function switchTo(idx) {
        if (idx >= 0 && idx < _layoutsModel.count) {
            const item = _layoutsModel.get(idx);
            const code = item.token.replace(/\(.*\)$/, "").trim();
            Quickshell.execDetached(["setxkbmap", "-layout", code]);
            _queryActiveLayout.running = true;
        }
    }

    function _buildXmlMap(xml) {
        const map = {};

        const re = /<name>\s*([^<]+?)\s*<\/name>[\s\S]*?<description>\s*([^<]+?)\s*<\/description>/g;

        let m;
        while ((m = re.exec(xml)) !== null) {
            const code = (m[1] || "").trim();
            const desc = (m[2] || "").trim();
            if (!code || !desc)
                continue;
            map[code] = _short(desc);
        }

        if (Object.keys(map).length === 0)
            return;

        _xkbMap = map;

        if (_layoutsModel.count === 0) {
            _populateFromXkbMap();
        } else {
            const tmp = [];
            for (let i = 0; i < _layoutsModel.count; i++) {
                const it = _layoutsModel.get(i);
                tmp.push({
                    layoutIndex: it.layoutIndex,
                    token: it.token,
                    label: _pretty(it.token)
                });
            }
            _layoutsModel.clear();
            tmp.forEach(t => _layoutsModel.append(t));
        }
        _queryActiveLayout.running = true;
    }

    function _populateFromXkbMap() {
        const codes = Object.keys(_xkbMap);
        const preferred = ["us", "gb", "de", "fr", "dk", "no", "se", "fi", "it", "es",
                           "pt", "nl", "be", "ch", "jp", "kr", "cn", "tw", "ru", "ua",
                           "pl", "cz", "sk", "hu", "ro", "bg", "gr", "tr", "br", "latam"];
        _layoutsModel.clear();
        let idx = 0;
        const added = new Set();

        for (const p of preferred) {
            if (added.has(p)) continue;
            if (codes.includes(p)) {
                _layoutsModel.append({ layoutIndex: idx, token: p, label: _pretty(p) });
                added.add(p);
                idx++;
            }
        }
        for (const code of codes) {
            if (added.has(code)) continue;
            _layoutsModel.append({ layoutIndex: idx, token: code, label: _pretty(code) });
            added.add(code);
            idx++;
        }
    }

    function _short(desc) {
        const m = desc.match(/^(.*)\((.*)\)$/);
        if (!m)
            return desc;
        const lang = m[1].trim();
        const region = m[2].trim();
        const code = (region.split(/[,\s-]/)[0] || region).slice(0, 2).toUpperCase();
        return `${lang} (${code})`;
    }

    function _rebuildVisible() {
        _visibleModel.clear();

        let arr = [];
        for (let i = 0; i < _layoutsModel.count; i++)
            arr.push(_layoutsModel.get(i));

        arr = arr.filter(i => i.layoutIndex !== activeIndex);
        arr.forEach(i => _visibleModel.append(i));

        if (!Config.utilities.toasts.kbLimit)
            return;

        if (_layoutsModel.count > 4) {
            Toaster.toast(qsTr("Keyboard layout limit"), qsTr("XKB supports only 4 layouts at a time"), "warning");
        }
    }

    function _pretty(token) {
        const code = token.replace(/\(.*\)$/, "").trim();
        if (_xkbMap[code])
            return code.toUpperCase() + " - " + _xkbMap[code];
        return code.toUpperCase() + " - " + code;
    }

    visible: false

    ListModel {
        id: _visibleModel
    }

    ListModel {
        id: _layoutsModel
    }

    Process {
        id: _xkbXmlBase

        command: ["xmllint", "--xpath", "//layout/configItem[name and description]", "/usr/share/X11/xkb/rules/base.xml"]
        stdout: StdioCollector {
            onStreamFinished: model._buildXmlMap(text)
        }
        onRunningChanged: if (!running && (typeof _xkbXmlBase.exitCode !== "undefined") && _xkbXmlBase.exitCode !== 0) // qmllint disable missing-property
            _xkbXmlEvdev.running = true
    }

    Process {
        id: _xkbXmlEvdev

        command: ["xmllint", "--xpath", "//layout/configItem[name and description]", "/usr/share/X11/xkb/rules/evdev.xml"]
        stdout: StdioCollector {
            onStreamFinished: model._buildXmlMap(text)
        }
    }

    Process {
        id: _queryActiveLayout

        command: ["mmsg", "get", "keyboardlayout"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text);
                    const layoutName = (j?.layout || "").trim();
                    const code = _layoutNameToCode(layoutName);

                    let foundIdx = -1;
                    for (let i = 0; i < _layoutsModel.count; i++) {
                        const it = _layoutsModel.get(i);
                        const itCode = it.token.replace(/\(.*\)$/, "").trim();
                        if (itCode === code) {
                            foundIdx = i;
                            break;
                        }
                    }

                    model.activeIndex = foundIdx;
                    model.activeLabel = foundIdx >= 0 ? _layoutsModel.get(foundIdx).label : "";
                } catch (e) {
                    model.activeIndex = -1;
                    model.activeLabel = "";
                }
                model._rebuildVisible();
            }
        }
    }

    function _layoutNameToCode(name) {
        const lower = name.toLowerCase();
        const known = {
            "english (us)": "us",
            "english (uk)": "gb",
            "german": "de",
            "french": "fr",
            "danish": "dk",
            "norwegian": "no",
            "swedish": "se",
            "finnish": "fi",
            "italian": "it",
            "spanish": "es",
            "portuguese": "pt",
            "dutch": "nl",
            "belgian": "be",
            "swiss": "ch",
            "japanese": "jp",
            "korean": "kr",
            "chinese": "cn",
            "russian": "ru",
            "ukrainian": "ua",
            "polish": "pl",
            "czech": "cz",
            "slovak": "sk",
            "hungarian": "hu",
            "romanian": "ro",
            "bulgarian": "bg",
            "greek": "gr",
            "turkish": "tr",
            "brazilian": "br",
        };
        for (const [key, val] of Object.entries(known)) {
            if (lower.includes(key)) return val;
        }
        const m = lower.match(/^([a-z]{2})\b/);
        return m ? m[1] : "us";
    }
}
