import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

// Pins of the prayers' texts: each text opens and closes with its source's words and keeps its length in
// characters, so an accidental edit fails here. scripts/check-texts.py checks every text, word for word,
// against its downloaded source.

(:test)
module TextPins {

    // For each prayer, in order: [its opening words, its closing words, its length in characters].
    function pins() as Array<Array> {
        return [
            ["Ven, Espíritu Santo,\nllena", "nuestro Señor. Amén.", 381],
            ["Ven, Espíritu Creador,\nvisita", "de los siglos. Amén.", 819],
            ["Ven, Espíritu divino,\nmanda", "y danos tu gozo eterno.", 822],
            ["El Señor es mi pastor,", "por muy largo tiempo.", 529],
            ["El Señor es mi luz y mi salvación,", "ten valor y espera en el Señor.", 1472],
            ["¡Ten piedad de mí, oh Dios,", "novillos en tu altar.", 1466],
            ["«Mi alma canta la grandeza del Señor,", "descendencia para siempre».", 733],
            ["El ángel del Señor anunció a María.", "Amén.\nGloria al Padre...", 667],
            ["Alma de Cristo, santifícame.", "de los siglos. Amén", 396],
            ["Señor, hazme un instrumento de tu paz:", "a la vida. Amén.", 588],
            ["Nada te turbe,\nnada te espante;", "Sólo Dios basta.", 143],
            ["Padre, me pongo en tus manos,", "porque Tú eres mi Padre.", 407],
            ["San Miguel Arcángel, defiéndenos", "de las almas. Amén.", 384]
        ] as Array<Array>;
    }

    function endsWith(text as String, end as String) as Boolean {
        return text.length() >= end.length() && text.substring(text.length() - end.length(), text.length()).equals(end);
    }
}

// Every prayer's text opens and closes with its source's words, at its length in characters.
(:test)
function everyTextKeepsItsOpeningItsCloseAndItsLength(logger as Logger) as Boolean {
    TestLanguage.use(logger, I18n.SPA);
    var pins = TextPins.pins();
    var ok = pins.size() == Prayers.COUNT;
    for (var prayer = 0; prayer < Prayers.COUNT && prayer < pins.size(); prayer++) {
        var text = Prayers.text(prayer);
        var pin = pins[prayer];
        var opens = text.find(pin[0] as String) == 0;
        var closes = TextPins.endsWith(text, pin[1] as String);
        var length = text.length() == pin[2];
        if (!(opens && closes && length)) {
            logger.debug("CHANGED '" + Prayers.title(prayer) + "': opens=" + opens + " closes=" + closes + " length " + text.length()
                + " (pinned " + pin[2] + ")");
        }
        ok = ok && opens && closes && length;
    }
    return ok;
}

// The Magníficat reads the two words the source mistyped as the Bible has them (Lc 1, 48-49): "él miró" and
// "ha hecho", never the page's "el miró" and "he hecho" (scripts/check-texts.py records both corrections).
(:test)
function magnificatReadsTheCorrectedWords(logger as Logger) as Boolean {
    TestLanguage.use(logger, I18n.SPA);
    var text = Prayers.text(6);
    var ok = Prayers.title(6).equals("Magníficat") && text.find("porque él miró") != null
        && text.find("el Todopoderoso ha hecho") != null && text.find("el miró") == null && text.find("he hecho") == null;
    logger.debug("Magníficat corrected=" + ok);
    return ok;
}
