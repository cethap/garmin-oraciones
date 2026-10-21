import Toybox.Lang;

// Visible part of the Instinct 2 main display, row by row: the same limits the watch face uses,
// calibrated from its simulator screenshot. The bezel rounds the corners off, and on rows 0..72 the
// span ends where the opaque ring of the subscreen lens starts. The subscreen window inside the
// ring is not part of the main display (see ScreenArea.insideSubscreen for text drawn there).
// Test-only: release builds do not carry the table.
(:test)
module VisibleArea {

    const LAST_ROW = 175;

    // Visible main-display span per screen row y (0..175), inclusive, from the watch face calibration.
    const VISIBLE_LEFT = [
        36, 34, 33, 31, 30, 29, 27, 26, 25, 24, 22, 21, 20, 19, 18, 17,
        16, 15, 14, 13, 13, 12, 11, 10, 9, 9, 8, 7, 6, 6, 5, 4,
        4, 3, 2, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 2, 3, 4, 4, 5, 5,
        6, 6, 7, 8, 9, 9, 10, 11, 12, 13, 13, 14, 15, 17, 18, 18,
        19, 20, 21, 23, 24, 25, 26, 28, 29, 30, 32, 33, 35, 37, 38, 39
    ] as Array<Number>;
    const VISIBLE_RIGHT = [
        111, 110, 109, 108, 108, 107, 106, 106, 105, 105, 104, 104, 103, 103, 103, 102,
        102, 102, 101, 101, 101, 101, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
        100, 100, 100, 100, 101, 101, 101, 101, 102, 102, 102, 103, 103, 103, 104, 104,
        105, 105, 106, 106, 107, 108, 108, 109, 110, 111, 112, 113, 114, 115, 116, 116,
        117, 119, 120, 122, 124, 126, 128, 132, 136, 175, 175, 175, 175, 175, 175, 175,
        175, 175, 175, 175, 175, 175, 175, 175, 175, 175, 175, 175, 175, 175, 175, 175,
        175, 175, 175, 175, 175, 175, 175, 175, 175, 175, 175, 175, 175, 175, 175, 175,
        175, 175, 175, 175, 175, 175, 175, 175, 175, 175, 175, 175, 175, 175, 175, 175,
        175, 175, 175, 175, 175, 175, 175, 175, 174, 173, 173, 172, 171, 171, 170, 170,
        169, 169, 168, 167, 166, 166, 165, 164, 163, 161, 161, 160, 159, 158, 157, 157,
        156, 155, 154, 152, 151, 150, 149, 147, 146, 145, 143, 142, 140, 138, 137, 136
    ] as Array<Number>;

    // True when the screen box [left, top, right, bottom] lies on the screen and, for every row from
    // its top - margin to its bottom + margin (clamped to the screen), keeps margin px inside that
    // row's visible span: VISIBLE_LEFT[y] + margin <= left and right <= VISIBLE_RIGHT[y] - margin.
    function boxFits(box as Array<Float>, margin as Number) as Boolean {
        if (box[1] < 0 || box[3] > LAST_ROW + 1) {
            return false;
        }
        var last = box[3].toNumber();
        if (last < box[3]) {
            last += 1;
        }
        var first = clampRow(box[1].toNumber() - margin);
        last = clampRow(last + margin);
        for (var y = first; y <= last; y++) {
            if (box[0] < VISIBLE_LEFT[y] + margin || box[2] > VISIBLE_RIGHT[y] - margin) {
                return false;
            }
        }
        return true;
    }

    // Largest margin, up to maxMargin, the box keeps (see boxFits); -1 when it is not fully visible.
    function marginOf(box as Array<Float>, maxMargin as Number) as Number {
        for (var margin = maxMargin; margin >= 0; margin--) {
            if (boxFits(box, margin)) {
                return margin;
            }
        }
        return -1;
    }

    function clampRow(y as Number) as Number {
        if (y < 0) {
            return 0;
        }
        return y > LAST_ROW ? LAST_ROW : y;
    }
}
