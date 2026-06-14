/* Permut8 bank writer for the NuXJS REPL.

   Usage:
     NuXJS tools/createP8Bank.nuxjs.js --name <firmware-name> --code <file.gazl> --output <file.p8bank>
         [--logo <file.ivg>] [--about <file.txt>] [--config <text>] [--template <file.p8bank>] [--compact true]

   NuXJS exposes global `arguments` as [script.js, arguments...] and the file helpers read()/write().
   Ported from the original PikaScript tools/createP8Bank.pika.
*/

var CRLF = "\r\n";
var TAB = "\t";

function usageAndFail(message) {
	print(
		"usage: NuXJS tools/createP8Bank.nuxjs.js --name <firmware-name> --code <file.gazl> --output <file.p8bank>"
			+ " [--logo <file.ivg>] [--about <file.txt>] [--config <text>] [--template <file.p8bank>] [--compact true]"
	);
	throw new Error(message || "invalid arguments");
}

function readText(path) {
	var text = read(path);
	text = text.split("\r\n").join("\n");
	text = text.split("\r").join("\n");
	return text;
}

function quoteValue(text) {
	text = text.split("\\").join("\\\\");
	text = text.split('"').join('\\"');
	text = text.split("\t").join("\\t");
	return '"' + text + '"';
}

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
	var lines = source.split("\n");
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

function blockFromFile(label, path) {
	var text = readText(path);
	if (label === "Code" && opt.compact !== undefined && opt.compact !== "false" && opt.compact !== "0") {
		text = compactGAZL(text);
	}
	if (text.charAt(text.length - 1) === "\n") {
		text = text.substring(0, text.length - 1);
	}
	var out = TAB + TAB + label + ": {" + CRLF;
	if (text !== "") {
		var lines = text.split("\n");
		var i;
		for (i = 0; i < lines.length; ++i) {
			out += TAB + TAB + TAB + quoteValue(lines[i]) + CRLF;
		}
	}
	out += TAB + TAB + "}" + CRLF;
	return out;
}

function defaultProgram(id) {
	return TAB + TAB + id + ": {" + CRLF
		+ TAB + TAB + TAB + "Modified: false" + CRLF
		+ TAB + TAB + TAB + 'InputLevel: "0.00000000"' + CRLF
		+ TAB + TAB + TAB + 'Limiter: "Off"' + CRLF
		+ TAB + TAB + TAB + 'FilterFreq: "---"' + CRLF
		+ TAB + TAB + TAB + 'FilterPlacement: "Output"' + CRLF
		+ TAB + TAB + TAB + 'FeedbackAmount: "0.00000000"' + CRLF
		+ TAB + TAB + TAB + 'FeedbackFlip: "Off"' + CRLF
		+ TAB + TAB + TAB + 'FeedbackInvert: "Off"' + CRLF
		+ TAB + TAB + TAB + 'OutputLevel: "0.00000000"' + CRLF
		+ TAB + TAB + TAB + 'Mix: "100.00000000"' + CRLF
		+ TAB + TAB + TAB + 'ClockFreq: "44.10000229 kHz"' + CRLF
		+ TAB + TAB + TAB + 'SyncMode: "Off"' + CRLF
		+ TAB + TAB + TAB + 'Reverse: "Off"' + CRLF
		+ TAB + TAB + TAB + 'Operator1: "0"' + CRLF
		+ TAB + TAB + TAB + 'Operand1High: "0x00"' + CRLF
		+ TAB + TAB + TAB + 'Operand1Low: "0x00"' + CRLF
		+ TAB + TAB + TAB + 'Operator2: "0"' + CRLF
		+ TAB + TAB + TAB + 'Operand2High: "0x00"' + CRLF
		+ TAB + TAB + TAB + 'Operand2Low: "0x00"' + CRLF
		+ TAB + TAB + "}" + CRLF;
}

function defaultPrefix() {
	var out = "Permut8BankV2: {" + CRLF + TAB + "CurrentProgram: A0" + CRLF + TAB + "Programs: {" + CRLF;
	var bank;
	var prefix;
	var i;
	for (bank = 0; bank < 3; ++bank) {
		prefix = "ABC".charAt(bank);
		for (i = 0; i < 10; ++i) {
			out += defaultProgram(prefix + i);
		}
	}
	out += TAB + "}" + CRLF;
	return out;
}

function templatePrefix(path) {
	var text = readText(path).split("\n").join(CRLF);
	var pattern = CRLF + TAB + "Firmware:";
	var i = text.indexOf(pattern);
	if (i < 0) {
		throw new Error("template does not contain a top-level Firmware block: " + path);
	}
	return text.substring(0, i + CRLF.length);
}

var opt = {};
var args = arguments;
var argCount = args.length;
var argIndex;
var key;

for (argIndex = 1; argIndex < argCount; argIndex += 2) {
	key = "" + args[argIndex];
	if (argIndex + 1 >= argCount || key.substring(0, 2) !== "--") {
		usageAndFail("malformed option near: " + key);
	}
	opt[key.substring(2)] = "" + args[argIndex + 1];
}

if (opt.name === undefined || opt.code === undefined || opt.output === undefined) {
	usageAndFail("missing required --name, --code, or --output");
}

var out = opt.template !== undefined ? templatePrefix(opt.template) : defaultPrefix();
out += TAB + "Firmware: {" + CRLF;
out += TAB + TAB + "Name: " + quoteValue(opt.name) + CRLF;
out += TAB + TAB + "Config: " + quoteValue(opt.config !== undefined ? opt.config : "") + CRLF;
out += blockFromFile("Code", opt.code);
if (opt.logo !== undefined) {
	out += CRLF + blockFromFile("Logo", opt.logo);
}
if (opt.about !== undefined) {
	out += CRLF + blockFromFile("About", opt.about);
}
out += TAB + "}" + CRLF + "}" + CRLF;
write(opt.output, out);
