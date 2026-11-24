import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    // ---------------------------------------------------------------
    // Peripheral list straight from UPower.
    // Deliberately NOT using BatteryService.peripheralDevices, because
    // that property returns [] unless refCount > 0 (i.e. unless a DMS
    // built-in battery widget is instantiated) — on desktops without a
    // laptop battery that never happens.
    // ---------------------------------------------------------------
    readonly property var allDevices: {
        const list = UPower.devices.values || [];
        return list.filter(dev => {
            if (!dev || !dev.ready)
                return false;
            if (dev.isLaptopBattery)
                return false;
            if (dev.type === UPowerDeviceType.LinePower || dev.type === UPowerDeviceType.Monitor || dev.type === UPowerDeviceType.Ups)
                return false;
            return dev.percentage > 0;
        }).map(dev => ({
                    "name": dev.model || UPowerDeviceType.toString(dev.type),
                    "percentage": Math.max(0, Math.min(100, Math.round(dev.percentage * 100))),
                    "type": dev.type,
                    "icon": iconForType(dev.type),
                    "charging": dev.state === UPowerDeviceState.Charging,
                    "state": dev.state
                })).sort((a, b) => a.percentage - b.percentage);
    }

    // Optional low-battery filter: while enabled, devices at or above the
    // threshold are dropped from the bar and the popout.
    readonly property bool lowOnly: pluginData.lowBatteryOnly === true
    readonly property int lowThreshold: {
        const v = pluginData.lowBatteryThreshold;
        return typeof v === "number" ? Math.min(100, Math.max(5, v)) : 50;
    }

    readonly property var devices: {
        if (!lowOnly)
            return allDevices;
        return allDevices.filter(dev => dev.percentage < lowThreshold);
    }

    readonly property int hiddenCount: allDevices.length - devices.length

    readonly property var primary: devices.length > 0 ? devices[0] : null
    readonly property bool showPercent: pluginData.showPercent !== false
    readonly property bool hideWhenEmpty: pluginData.hideWhenEmpty !== false

    function tr(term) {
        return I18n.trFor("peripheralBattery", term);
    }

    function iconForType(type) {
        switch (type) {
        case UPowerDeviceType.Keyboard:
            return "keyboard";
        case UPowerDeviceType.Mouse:
        case UPowerDeviceType.Touchpad:
            return "mouse";
        case UPowerDeviceType.Headphones:
            return "headphones";
        case UPowerDeviceType.Headset:
            return "headset_mic";
        case UPowerDeviceType.Speakers:
            return "speaker";
        case UPowerDeviceType.GamingInput:
            return "sports_esports";
        case UPowerDeviceType.Phone:
            return "smartphone";
        case UPowerDeviceType.Tablet:
            return "tablet";
        case UPowerDeviceType.MediaPlayer:
            return "play_circle";
        case UPowerDeviceType.Wearable:
            return "watch";
        case UPowerDeviceType.Pen:
            return "stylus";
        case UPowerDeviceType.BluetoothGeneric:
            return "bluetooth";
        default:
            return "devices_other";
        }
    }

    function colorFor(percentage, charging) {
        if (charging)
            return Theme.primary;
        if (percentage <= 15)
            return Theme.error;
        if (percentage <= 30)
            return Theme.tertiary;
        return Theme.surfaceText;
    }

    visible: !(hideWhenEmpty && devices.length === 0)

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DIcon {
                visible: root.devices.length === 0
                name: "battery_unknown"
                size: Theme.iconSizeSmall
                color: Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }

            Repeater {
                model: root.devices

                Row {
                    required property var modelData
                    spacing: Theme.spacingXXS
                    anchors.verticalCenter: parent.verticalCenter

                    DIcon {
                        name: modelData.icon
                        size: Theme.iconSizeSmall
                        color: root.colorFor(modelData.percentage, modelData.charging)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    DIcon {
                        visible: modelData.charging
                        name: "bolt"
                        size: root.textSize
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        visible: root.showPercent
                        text: modelData.percentage + "%"
                        font.pixelSize: root.textSize
                        color: root.colorFor(modelData.percentage, modelData.charging)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXXS

            DIcon {
                name: root.primary ? root.primary.icon : "battery_unknown"
                size: Theme.iconSizeSmall
                color: root.primary ? root.colorFor(root.primary.percentage, root.primary.charging) : Theme.surfaceVariantText
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                visible: root.showPercent && root.primary !== null
                text: root.primary ? root.primary.percentage + "%" : ""
                font.pixelSize: root.textSize - 1
                color: root.primary ? root.colorFor(root.primary.percentage, root.primary.charging) : Theme.surfaceVariantText
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    popoutWidth: Theme.listItemHeight * 6
    popoutHeight: 0

    popoutContent: Component {
        PopoutComponent {
            id: popout
            headerText: root.tr("Peripherals")
            detailsText: {
                if (root.devices.length === 0) {
                    if (root.hiddenCount > 0)
                        return root.tr("%1 device(s) hidden by threshold").arg(root.hiddenCount);
                    return root.tr("No peripheral reported");
                }
                const base = root.tr("%1 device(s)").arg(root.devices.length);
                return root.hiddenCount > 0 ? base + " · " + root.tr("%1 hidden").arg(root.hiddenCount) : base;
            }

            Column {
                width: parent.width
                spacing: Theme.spacingS

                Repeater {
                    model: root.devices

                    Rectangle {
                        required property var modelData
                        width: parent.width
                        height: rowContent.implicitHeight + Theme.spacingM * 2
                        radius: Theme.cornerRadius
                        color: Theme.surfaceContainerHigh

                        Row {
                            id: rowContent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: Theme.spacingM
                            anchors.rightMargin: Theme.spacingM
                            spacing: Theme.spacingM

                            DIcon {
                                name: modelData.charging ? "bolt" : modelData.icon
                                size: Theme.iconSize
                                color: root.colorFor(modelData.percentage, modelData.charging)
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                width: parent.width - Theme.iconSize - percentText.width - Theme.spacingM * 3
                                spacing: Theme.spacingXXS
                                anchors.verticalCenter: parent.verticalCenter

                                StyledText {
                                    width: parent.width
                                    text: modelData.name
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    width: parent.width
                                    text: root.tr(UPowerDeviceState.toString(modelData.state)) + " · " + root.tr(UPowerDeviceType.toString(modelData.type))
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    elide: Text.ElideRight
                                }
                            }

                            StyledText {
                                id: percentText
                                text: modelData.percentage + "%"
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Theme.fontWeightMedium
                                color: root.colorFor(modelData.percentage, modelData.charging)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                StyledText {
                    visible: root.devices.length === 0
                    width: parent.width
                    text: root.hiddenCount > 0 ? root.tr("Every peripheral is at or above %1%. Raise the threshold or turn off \"Only show low battery\".").arg(root.lowThreshold) : root.tr("No peripheral device reports a battery level.\nBluetooth peripherals appear here only when the kernel or BlueZ exposes a battery interface.")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
