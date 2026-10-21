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
            ["Padre nuestro que estás en el cielo,", "y líbranos del mal. Amén.", 318],
            ["Pater noster qui es in caelis:", "sed libera nos a Malo. Amen", 306],
            ["Our Father, who art in heaven,", "deliver us from evil.\nAmen.", 291],
            ["Dios te salve, María,", "la hora de nuestra muerte. Amén", 251],
            ["Ave, María, grátia plena,", "in hora mortis nostræ.\nAmen.", 200],
            ["Hail, Mary, full of grace,", "at the hour of our death.\nAmen.", 210],
            ["Ven, Espíritu Santo,\nllena", "nuestro Señor. Amén.", 381],
            ["Ven, Espíritu divino,\nmanda", "y danos tu gozo eterno.", 822],
            ["Protégeme, Dios mío,\nporque me refugio en ti.", "felicidad eterna a tu derecha.", 899],
            ["El Señor es mi pastor,", "por muy largo tiempo.", 529],
            ["El Señor es mi luz y mi salvación,", "ten valor y espera en el Señor.", 1472],
            ["¡Ten piedad de mí, oh Dios,", "novillos en tu altar.", 1466],
            ["¡Qué amable es tu Morada,\nSeñor del Universo!", "el hombre que confía en ti!", 1059],
            ["¡Aleluya! ¡Den gracias al Señor,", "porque es eterno su amor!", 1674],
            ["Felices los que tienen alma de pobres,", "los profetas que los precedieron.", 848],
            ["Aunque yo hablara todas las lenguas", "la más grande de todas es el amor.", 1452],
            ["Al principio existía la Palabra,", "que está en el seno del Padre.", 1605],
            ["«Mi alma canta la grandeza del Señor,", "descendencia para siempre».", 733],
            ["El ángel del Señor anunció a María.", "Amén.\nGloria al Padre...", 667],
            ["Bendita sea tu pureza", "no me dejes, Madre mía.", 238],
            ["¡Oh Señora mía!, ¡Oh Madre mía!,", "posesión vuestra.\nAmén.", 300],
            ["Creo, Jesús mío,\nque estáis", "me aparte de Ti. Amén.", 359],
            ["Te adoro con devoción, Dios escondido,", "viendo tu gloria.\nAmén.", 1094],
            ["Padre bueno, sé que estás conmigo.", "Obispo para este mes.\nAmén.", 584],
            ["Señor mío Jesucristo, Dios y hombre verdadero,", "que me fuera impuesta. Amén", 392],
            ["Visita, Señor, esta habitación:", "Por Jesucristo nuestro Señor.", 213],
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
    var magnificat = Prayers.indexOf("magnificat") as Number;
    var text = Prayers.text(magnificat);
    var ok = Prayers.title(magnificat).equals("Magníficat") && text.find("porque él miró") != null
        && text.find("el Todopoderoso ha hecho") != null && text.find("el miró") == null && text.find("he hecho") == null;
    logger.debug("Magníficat corrected=" + ok);
    return ok;
}

// The Himno al amor reads the two words the source mistyped as the Bible has them (1 Cor 13, 5 and 13): "no
// tiene en cuenta" and "la más grande de todas", never the page's "no tienen en cuenta" and "la más grande
// todas" (scripts/check-texts.py records both corrections).
(:test)
function hymnOfLoveReadsTheCorrectedWords(logger as Logger) as Boolean {
    TestLanguage.use(logger, I18n.SPA);
    var hymn = Prayers.indexOf("himno_amor");
    if (hymn == null) {
        logger.debug("no himno_amor");
        return false;
    }
    var text = Prayers.text(hymn as Number);
    var ok = text.find("no tiene en cuenta el mal recibido") != null && text.find("la más grande de todas es el amor") != null
        && text.find("no tienen en cuenta") == null && text.find("grande todas") == null;
    logger.debug("Himno al amor corrected=" + ok);
    return ok;
}

// Every prayer reads in the pages it was measured in, ceil(lines / 4) fixed pages of centered lines (Psalm
// 136, the longest, in 31 pages): a change to a text or to the reading layout that changes a prayer's
// length on the watch fails here.
(:test)
function everyPrayerReadsInItsPages(logger as Logger) as Boolean {
    TestLanguage.use(logger, I18n.SPA);
    var dc = ScreenArea.measuringDc();
    var expected = [7, 6, 6, 5, 4, 4, 7, 15, 17, 11, 28, 28, 20, 31, 15, 25, 28, 13, 13, 5, 6, 7, 20, 11, 8, 4, 7, 11, 3, 8, 7]
        as Array<Number>;
    var pages = [] as Array<Number>;
    for (var prayer = 0; prayer < Prayers.COUNT; prayer++) {
        pages.add(ScrollCheck.expectedPages(ReadingCheck.open(prayer, null, dc).bodyLines().size()).size());
    }
    logger.debug("pages " + pages + " pinned " + expected + " at " + ReadingLayout.visibleLines() + " lines a page");
    return ReadingLayout.visibleLines() == 4 && pages.toString().equals(expected.toString());
}
