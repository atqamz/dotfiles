pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property var categories: [
        { name: "Smileys", items: [
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
            { ch: "🤓", name: "nerd glasses" }
        ]},
        { name: "Hands", items: [
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
            { ch: "👊", name: "fist bump punch" }
        ]},
        { name: "Hearts", items: [
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
            { ch: "💟", name: "heart decoration" }
        ]},
        { name: "Symbols", items: [
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
            { ch: "✅", name: "check mark green tick" },
            { ch: "❌", name: "cross x wrong" },
            { ch: "❓", name: "question mark" },
            { ch: "❗", name: "exclamation mark" },
            { ch: "⚠️", name: "warning" },
            { ch: "⚡", name: "high voltage lightning" }
        ]},
        { name: "Food", items: [
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
            { ch: "🍵", name: "tea" }
        ]},
        { name: "Animals", items: [
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
            { ch: "🙊", name: "speak no evil monkey" }
        ]},
        { name: "Tech", items: [
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
            { ch: "💡", name: "light bulb idea" }
        ]}
    ]

    readonly property var allEmojis: {
        const out = [];
        for (let i = 0; i < categories.length; ++i) {
            for (let j = 0; j < categories[i].items.length; ++j) {
                const e = categories[i].items[j];
                out.push({ ch: e.ch, name: e.name, category: categories[i].name });
            }
        }
        return out;
    }

    property var recents: []

    function bumpRecent(ch: string): void {
        const cur = root.recents.filter(c => c !== ch);
        cur.unshift(ch);
        root.recents = cur.slice(0, 24);
        recentsFile.setText(JSON.stringify(root.recents));
    }

    FileView {
        id: recentsFile
        path: Quickshell.env("HOME") + "/.config/quickshell/state/emoji-recents.json"
        watchChanges: false
        onLoaded: {
            try {
                const arr = JSON.parse(this.text());
                if (Array.isArray(arr)) root.recents = arr.slice(0, 24);
            } catch (_) { /* ignore */ }
        }
        Component.onCompleted: recentsFile.reload()
    }
}
