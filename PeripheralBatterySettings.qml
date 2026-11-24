import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.DCommon.Widgets

PluginSettings {
    id: root
    pluginId: "peripheralBattery"

    function tr(term) {
        return I18n.trFor("peripheralBattery", term);
    }

    StyledText {
        width: parent.width
        text: root.tr("Peripheral Battery")
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Theme.fontWeightMedium
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: root.tr("Reads peripheral battery levels directly from UPower (keyboard, mouse, headset, controller). USB peripherals work out of the box; Bluetooth peripherals only appear once the kernel or BlueZ exposes a battery interface for them.")
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    ToggleSetting {
        settingKey: "showPercent"
        label: root.tr("Show percentage")
        description: root.tr("Display the numeric battery level next to the icon")
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "hideWhenEmpty"
        label: root.tr("Hide when no device")
        description: root.tr("Hide the widget entirely while no peripheral reports a battery")
        defaultValue: true
    }

    ToggleSetting {
        id: lowOnlyToggle
        settingKey: "lowBatteryOnly"
        label: root.tr("Only show low battery")
        description: root.tr("Hide every device whose battery is at or above the threshold below")
        defaultValue: false
    }

    SliderSetting {
        settingKey: "lowBatteryThreshold"
        label: root.tr("Low battery threshold")
        description: root.tr("Devices at or above this level are hidden while \"Only show low battery\" is on.")
        defaultValue: 50
        minimum: 5
        maximum: 100
        unit: "%"
        visible: lowOnlyToggle.value
    }
}
