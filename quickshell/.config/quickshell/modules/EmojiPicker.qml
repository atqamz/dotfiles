import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import qs.components

Scope {
    id: root

    property bool open: false
    property string query: ""
    property int currentIndex: 0

    readonly property var emojis: [
        { ch: "😀", name: "grinning face" },
        { ch: "😁", name: "beaming face" },
        { ch: "😂", name: "tears of joy" },
        { ch: "🤣", name: "rolling on floor laughing rofl" },
        { ch: "😃", name: "grinning big eyes" },
        { ch: "😄", name: "grinning smiling eyes" },
        { ch: "😅", name: "grinning sweat" },
        { ch: "😆", name: "grinning squinting" },
        { ch: "😉", name: "winking" },
        { ch: "😊", name: "smiling blush" },
        { ch: "😎", name: "smiling sunglasses cool" },
        { ch: "😍", name: "smiling heart eyes love" },
        { ch: "😘", name: "kiss face" },
        { ch: "🥰", name: "smiling hearts love" },
        { ch: "🤔", name: "thinking" },
        { ch: "🤨", name: "raised eyebrow skeptical" },
        { ch: "😐", name: "neutral" },
        { ch: "😑", name: "expressionless" },
        { ch: "😶", name: "no mouth" },
        { ch: "🙄", name: "rolling eyes" },
        { ch: "😏", name: "smirking" },
        { ch: "😣", name: "persevering" },
        { ch: "😥", name: "sad relieved" },
        { ch: "😮", name: "open mouth surprise" },
        { ch: "🤐", name: "zipper mouth" },
        { ch: "😯", name: "hushed" },
        { ch: "😪", name: "sleepy" },
        { ch: "😫", name: "tired" },
        { ch: "😴", name: "sleeping" },
        { ch: "😌", name: "relieved" },
        { ch: "😛", name: "tongue" },
        { ch: "😜", name: "winking tongue" },
        { ch: "😝", name: "squinting tongue" },
        { ch: "🤤", name: "drooling" },
        { ch: "😒", name: "unamused annoyed" },
        { ch: "😓", name: "downcast sweat" },
        { ch: "😔", name: "pensive sad" },
        { ch: "😕", name: "confused" },
        { ch: "🙃", name: "upside down" },
        { ch: "🤑", name: "money mouth" },
        { ch: "😲", name: "astonished shocked" },
        { ch: "☹️", name: "frowning" },
        { ch: "🙁", name: "slightly frowning" },
        { ch: "😖", name: "confounded" },
        { ch: "😞", name: "disappointed sad" },
        { ch: "😟", name: "worried" },
        { ch: "😤", name: "huffing triumph" },
        { ch: "😢", name: "crying tear" },
        { ch: "😭", name: "loudly crying sob" },
        { ch: "😦", name: "frowning open mouth" },
        { ch: "😧", name: "anguished" },
        { ch: "😨", name: "fearful scared" },
        { ch: "😩", name: "weary" },
        { ch: "🤯", name: "exploding head mind blown" },
        { ch: "😬", name: "grimacing" },
        { ch: "😰", name: "anxious sweat" },
        { ch: "😱", name: "screaming fear scream" },
        { ch: "🥵", name: "hot" },
        { ch: "🥶", name: "cold freezing" },
        { ch: "😳", name: "flushed" },
        { ch: "🤪", name: "zany silly" },
        { ch: "😵", name: "dizzy" },
        { ch: "🥴", name: "woozy drunk" },
        { ch: "😡", name: "pouting angry rage" },
        { ch: "😠", name: "angry" },
        { ch: "🤬", name: "swearing cursing" },
        { ch: "😷", name: "medical mask" },
        { ch: "🤒", name: "thermometer sick" },
        { ch: "🤕", name: "head bandage hurt" },
        { ch: "🤢", name: "nauseated sick" },
        { ch: "🤮", name: "vomiting" },
        { ch: "🤧", name: "sneezing" },
        { ch: "😇", name: "halo innocent angel" },
        { ch: "🤠", name: "cowboy" },
        { ch: "🤡", name: "clown" },
        { ch: "🥳", name: "party hat celebrate" },
        { ch: "🥺", name: "pleading begging" },
        { ch: "🤥", name: "lying pinocchio" },
        { ch: "🤫", name: "shushing quiet" },
        { ch: "🤭", name: "hand over mouth" },
        { ch: "🧐", name: "monocle inspect" },
        { ch: "🤓", name: "nerd glasses" },
        { ch: "👍", name: "thumbs up ok yes" },
        { ch: "👎", name: "thumbs down no" },
        { ch: "👌", name: "ok hand" },
        { ch: "✌️", name: "peace victory" },
        { ch: "🤞", name: "fingers crossed hope" },
        { ch: "🤟", name: "love you sign" },
        { ch: "🤘", name: "rock metal horns" },
        { ch: "🤙", name: "call me hang loose" },
        { ch: "👈", name: "point left" },
        { ch: "👉", name: "point right" },
        { ch: "👆", name: "point up" },
        { ch: "👇", name: "point down" },
        { ch: "☝️", name: "point up index" },
        { ch: "✋", name: "raised hand stop" },
        { ch: "🤚", name: "raised back hand" },
        { ch: "🖐️", name: "five fingers splayed" },
        { ch: "🖖", name: "vulcan salute" },
        { ch: "👋", name: "waving hello bye" },
        { ch: "🤝", name: "handshake deal" },
        { ch: "🙏", name: "praying thanks please" },
        { ch: "💪", name: "flexed biceps strong" },
        { ch: "🦾", name: "mechanical arm" },
        { ch: "👏", name: "clap" },
        { ch: "🙌", name: "raising hands celebration" },
        { ch: "👐", name: "open hands" },
        { ch: "🤲", name: "palms up together" },
        { ch: "✊", name: "raised fist" },
        { ch: "👊", name: "fist bump punch" },
        { ch: "❤️", name: "red heart love" },
        { ch: "🧡", name: "orange heart" },
        { ch: "💛", name: "yellow heart" },
        { ch: "💚", name: "green heart" },
        { ch: "💙", name: "blue heart" },
        { ch: "💜", name: "purple heart" },
        { ch: "🖤", name: "black heart" },
        { ch: "🤍", name: "white heart" },
        { ch: "🤎", name: "brown heart" },
        { ch: "💔", name: "broken heart" },
        { ch: "❣️", name: "heart exclamation" },
        { ch: "💕", name: "two hearts" },
        { ch: "💖", name: "sparkling heart" },
        { ch: "💗", name: "growing heart" },
        { ch: "💘", name: "heart arrow cupid" },
        { ch: "💝", name: "heart ribbon gift" },
        { ch: "💞", name: "revolving hearts" },
        { ch: "💟", name: "heart decoration" },
        { ch: "✨", name: "sparkles" },
        { ch: "⭐", name: "star" },
        { ch: "🌟", name: "glowing star" },
        { ch: "🔥", name: "fire flame hot lit" },
        { ch: "💯", name: "hundred 100" },
        { ch: "💢", name: "anger symbol" },
        { ch: "💥", name: "boom explosion" },
        { ch: "💫", name: "dizzy stars" },
        { ch: "💦", name: "sweat droplets" },
        { ch: "💨", name: "dashing away" },
        { ch: "🎉", name: "party popper celebration" },
        { ch: "🎊", name: "confetti ball" },
        { ch: "🎁", name: "gift present" },
        { ch: "🎂", name: "birthday cake" },
        { ch: "🍰", name: "cake slice" },
        { ch: "🍕", name: "pizza" },
        { ch: "🍔", name: "burger" },
        { ch: "🍟", name: "fries" },
        { ch: "🌭", name: "hot dog" },
        { ch: "🍦", name: "ice cream soft" },
        { ch: "🍩", name: "donut" },
        { ch: "🍪", name: "cookie" },
        { ch: "🍫", name: "chocolate bar" },
        { ch: "🍿", name: "popcorn" },
        { ch: "🍺", name: "beer" },
        { ch: "🍻", name: "clinking beers" },
        { ch: "🍷", name: "wine glass" },
        { ch: "🥃", name: "tumbler whiskey" },
        { ch: "🍸", name: "cocktail" },
        { ch: "☕", name: "coffee hot beverage" },
        { ch: "🍵", name: "tea" },
        { ch: "🐶", name: "dog face" },
        { ch: "🐱", name: "cat face" },
        { ch: "🐭", name: "mouse face" },
        { ch: "🐹", name: "hamster" },
        { ch: "🐰", name: "rabbit bunny" },
        { ch: "🦊", name: "fox" },
        { ch: "🐻", name: "bear" },
        { ch: "🐼", name: "panda" },
        { ch: "🐨", name: "koala" },
        { ch: "🐯", name: "tiger" },
        { ch: "🦁", name: "lion" },
        { ch: "🐸", name: "frog" },
        { ch: "🐵", name: "monkey face" },
        { ch: "🙈", name: "see no evil monkey" },
        { ch: "🙉", name: "hear no evil monkey" },
        { ch: "🙊", name: "speak no evil monkey" },
        { ch: "🌍", name: "earth africa europe" },
        { ch: "🌎", name: "earth americas" },
        { ch: "🌏", name: "earth asia" },
        { ch: "🌞", name: "sun face" },
        { ch: "🌝", name: "full moon face" },
        { ch: "🌚", name: "new moon face" },
        { ch: "⏰", name: "alarm clock" },
        { ch: "✅", name: "check mark green tick" },
        { ch: "❌", name: "cross x wrong" },
        { ch: "❓", name: "question mark" },
        { ch: "❗", name: "exclamation mark" },
        { ch: "⚠️", name: "warning" },
        { ch: "🚀", name: "rocket ship launch" },
        { ch: "💻", name: "laptop computer" },
        { ch: "🖥️", name: "desktop computer" },
        { ch: "⌨️", name: "keyboard" },
        { ch: "🖱️", name: "mouse computer" },
        { ch: "🎮", name: "video game gamepad" },
        { ch: "📱", name: "phone mobile" },
        { ch: "📷", name: "camera" },
        { ch: "🎵", name: "music note" },
        { ch: "🎶", name: "multiple notes" },
        { ch: "🔊", name: "speaker loud" },
        { ch: "🔇", name: "speaker muted" },
        { ch: "📚", name: "books" },
        { ch: "🔒", name: "locked" },
        { ch: "🔓", name: "unlocked" },
        { ch: "🔑", name: "key" },
        { ch: "🔧", name: "wrench tool" },
        { ch: "🔨", name: "hammer" },
        { ch: "💡", name: "light bulb idea" },
        { ch: "💰", name: "money bag" },
        { ch: "💸", name: "money flying" },
        { ch: "📈", name: "chart increasing" },
        { ch: "📉", name: "chart decreasing" },
        { ch: "🏠", name: "house home" },
        { ch: "🏢", name: "office building" },
        { ch: "🚗", name: "car" },
        { ch: "✈️", name: "airplane" },
        { ch: "🚲", name: "bicycle bike" },
        { ch: "🛏️", name: "bed sleep" },
        { ch: "🎯", name: "target bullseye" },
        { ch: "🎲", name: "dice game" },
        { ch: "🏆", name: "trophy win" },
        { ch: "🥇", name: "gold medal first" },
        { ch: "🥈", name: "silver medal second" },
        { ch: "🥉", name: "bronze medal third" },
        { ch: "⚡", name: "high voltage lightning" },
        { ch: "❄️", name: "snowflake" },
        { ch: "🌈", name: "rainbow" },
        { ch: "☂️", name: "umbrella" },
        { ch: "☀️", name: "sun" },
        { ch: "🌧️", name: "rain cloud" },
        { ch: "⛅", name: "sun behind cloud" }
    ]

    readonly property var filteredEmojis: {
        const q = root.query.toLowerCase();
        if (q.length === 0) return root.emojis;
        return root.emojis.filter(e => e.name.includes(q) || e.ch === q);
    }

    onFilteredEmojisChanged: root.currentIndex = 0

    function toggle(): void {
        root.open = !root.open;
        if (root.open) {
            root.query = "";
            root.currentIndex = 0;
        }
    }

    function moveSelection(delta: int): void {
        const len = root.filteredEmojis.length;
        if (len === 0) return;
        root.currentIndex = (root.currentIndex + delta + len) % len;
    }

    function copySelected(): void {
        const list = root.filteredEmojis;
        if (root.currentIndex < 0 || root.currentIndex >= list.length)
            return;
        const e = list[root.currentIndex];
        root.open = false;
        copyProc.command = ["sh", "-c", `printf '%s' '${e.ch}' | wl-copy`];
        copyProc.running = true;
    }

    Process { id: copyProc }

    IpcHandler {
        target: "emoji"
        function toggle(): void { root.toggle(); }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.open

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: Theme.scrim
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            onVisibleChanged: if (visible) searchField.forceActiveFocus()

            MouseArea {
                anchors.fill: parent
                onClicked: root.open = false
            }

            StyledRect {
                anchors.centerIn: parent
                width: 560
                height: 500
                color: Theme.surface
                border.color: Theme.outline
                border.width: 1
                radius: Theme.radius.large

                MouseArea { anchors.fill: parent }

                Column {
                    anchors.fill: parent
                    anchors.margins: Theme.padding.larger
                    spacing: Theme.spacing.large

                    Row {
                        width: parent.width
                        spacing: Theme.spacing.large

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "mood"
                            color: Theme.textVariant
                            font.pixelSize: 22
                            width: 28
                        }

                        TextField {
                            id: searchField
                            width: parent.width - 28 - parent.spacing
                            placeholderText: "Search emoji…"
                            color: Theme.text
                            placeholderTextColor: Theme.textMuted
                            font.pixelSize: Theme.font.size.large
                            font.family: Theme.font.family.sans
                            text: root.query
                            onTextChanged: if (text !== root.query) root.query = text
                            background: Rectangle {
                                color: Theme.surfaceContainer
                                border.color: Theme.outlineVariant
                                border.width: 1
                                radius: Theme.radius.normal
                            }
                            padding: Theme.padding.normal

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) {
                                    root.open = false;
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Down) {
                                    root.moveSelection(1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Up) {
                                    root.moveSelection(-1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.copySelected();
                                    event.accepted = true;
                                }
                            }
                        }
                    }

                    ListView {
                        width: parent.width
                        height: parent.height - searchField.height - parent.spacing
                        clip: true
                        keyNavigationEnabled: false
                        currentIndex: root.currentIndex
                        model: root.filteredEmojis
                        spacing: 2

                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                        delegate: StyledRect {
                            required property var modelData
                            required property int index
                            width: ListView.view.width
                            height: 34
                            color: index === root.currentIndex ? Theme.surfaceContainerHigh : "transparent"
                            radius: Theme.radius.normal

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: Theme.padding.large
                                anchors.rightMargin: Theme.padding.large
                                spacing: Theme.spacing.large

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.ch
                                    font.pixelSize: 20
                                    width: 28
                                }
                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.name
                                    color: Theme.textVariant
                                    font.pixelSize: Theme.font.size.normal
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: root.currentIndex = index
                                onClicked: {
                                    root.currentIndex = index;
                                    root.copySelected();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
