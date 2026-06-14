/* GAZL compactor for the NuXJS REPL.

   Usage:
     NuXJS tools/gazlCompactor.nuxjs.js <input.gazl> <output.gazl>

   Strips comments and redundant whitespace from compiled GAZL while preserving DATs string data.
   NuXJS exposes global `arguments` as [script.js, arguments...] and the file helpers read()/write().
   Ported from the original PikaScript tools/gazlCompactor.pika.
*/

function isSpace(ch) {
	return ch === " " || ch === "\t";
}

function trimRightSpaces(text) {
	var end = text.length;
	while (end > 0 && text.charAt(end - 1) === " ") {
		--end;
	}
	return text.substring(0, end);
}

function compactGAZL(source) {
	var lines = ("" + source).split(/\r\n|\n|\r/);
	var output = "";
	var lineIndex;
	var s;
	var i;
	var l;
	var ch;
	var tokenStart;

	for (lineIndex = 0; lineIndex < lines.length; ++lineIndex) {
		s = lines[lineIndex];
		i = 0;
		l = "";
		while (i < s.length && s.charAt(i) !== ";") {
			ch = s.charAt(i);
			if (isSpace(ch)) {
				while (i < s.length && isSpace(s.charAt(i))) {
					++i;
				}
				if (l !== "") {
					l += " ";
				}
			} else if (s.substring(i, i + 4) === "DATs") {
				l += s.substring(i);
				i = s.length;
			} else {
				tokenStart = i;
				while (i < s.length && !isSpace(s.charAt(i)) && s.charAt(i) !== ";") {
					++i;
				}
				l += s.substring(tokenStart, i);
			}
		}
		l = trimRightSpaces(l);
		if (l !== "") {
			output += l + "\n";
		}
	}

	return output;
}

if (!arguments || arguments.length !== 3) {
	print("usage: NuXJS tools/gazlCompactor.nuxjs.js <input.gazl> <output.gazl>");
	throw new Error("expected exactly two arguments");
}

write("" + arguments[2], compactGAZL(read("" + arguments[1])));
