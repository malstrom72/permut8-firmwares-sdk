'use strict';

// Post-processes the Docling-generated Permut8 User Guide Markdown:
//   1. strips an absolute path prefix from the given files
//   2. URL-encodes the artifacts folder reference
//   3. converts the Markdown-table Table of Contents into a bullet list
//
// Usage:
//   node tools/postprocessUserGuide.js <path-prefix-to-remove> <markdown-file> [json-file]
//
// Ported from the original PikaScript tools/postprocessUserGuide.pika. Files are read and
// written as latin1 so byte content round-trips exactly.

const fs = require('fs');
const path = require('path');

const ENCODING = 'latin1';

function usageAndExit() {
	console.error('usage: node tools/postprocessUserGuide.js <path-prefix-to-remove> <markdown-file> [json-file]');
	process.exit(1);
}

function readFile(path) {
	return fs.readFileSync(path, ENCODING);
}

function writeFile(path, contents) {
	fs.writeFileSync(path, contents, ENCODING);
}

function stripPrefix(path, prefix) {
	writeFile(path, readFile(path).split(prefix).join(''));
}

function trimPipes(line) {
	if (line.charAt(0) === '|') {
		line = line.substring(1);
	}
	if (line.charAt(line.length - 1) === '|') {
		line = line.substring(0, line.length - 1);
	}
	return line;
}

function isSeparatorLine(line) {
	return trimPipes(line).replace(/[|-]/g, '').trim() === '';
}

function isDigit(ch) {
	return ch >= '0' && ch <= '9';
}

// Detects the "Title ........ 42" dot-leader pattern. On a match, returns the cleaned title
// and the trailing page number; otherwise returns the entry unchanged with no page.
function removeTocPage(entry) {
	entry = entry.trim();
	let end = entry.length;
	while (end > 0 && isDigit(entry.charAt(end - 1))) {
		--end;
	}
	if (end === entry.length) {
		return { entry: entry, page: '' };
	}
	const page = entry.substring(end);
	let i = end;
	while (i > 0 && (entry.charAt(i - 1) === ' ' || entry.charAt(i - 1) === '\t')) {
		--i;
	}
	const dotEnd = i;
	while (i > 0 && entry.charAt(i - 1) === '.') {
		--i;
	}
	if (dotEnd - i >= 3) {
		return { entry: entry.substring(0, i).trim(), page: page };
	}
	return { entry: entry, page: '' };
}

function cleanToc(block) {
	let out = '';
	let foundTableRows = false;
	const lines = block.split('\n');
	for (let li = 0; li < lines.length; ++li) {
		const line = lines[li];
		if (line.charAt(0) === '|' && !isSeparatorLine(line)) {
			foundTableRows = true;
			let entry = '';
			const cols = trimPipes(line).split('|');
			for (let ci = 0; ci < cols.length; ++ci) {
				const col = cols[ci].trim();
				if (col !== '') {
					if (entry !== '') {
						entry += ' ';
					}
					entry += col;
				}
			}
			entry = entry.trim();
			if (entry !== '') {
				const cleaned = removeTocPage(entry);
				if (cleaned.entry !== '') {
					if (out !== '') {
						out += '\n';
					}
					out += '- ' + cleaned.entry + (cleaned.page !== '' ? ', p. ' + cleaned.page : '');
				}
			}
		}
	}
	return foundTableRows ? out + '\n' : block;
}

function postprocessMarkdown(path) {
	let text = readFile(path);
	text = text.split('Permut8 User Guide_artifacts/').join('Permut8%20User%20Guide_artifacts/');
	const before = '## Table of Contents\n\n';
	const start = text.indexOf(before);
	if (start >= 0) {
		const blockStart = start + before.length;
		const rest = text.substring(blockStart);
		const nextHeading = rest.indexOf('\n## ');
		if (nextHeading >= 0) {
			const blockEnd = blockStart + nextHeading;
			text = text.substring(0, blockStart) + cleanToc(text.substring(blockStart, blockEnd)) + text.substring(blockEnd);
		}
	}
	writeFile(path, text);
}

function prunePageImages(guideDir, jsonFile) {
	const data = JSON.parse(fs.readFileSync(jsonFile, 'utf8'));

	if (data.pages) {
		for (const page of Object.values(data.pages)) {
			delete page.image;
		}
	}

	const artifactDir = path.join(guideDir, path.basename(jsonFile, '.docling.json') + '_artifacts');
	if (fs.existsSync(artifactDir)) {
		for (const name of fs.readdirSync(artifactDir)) {
			if (/^page_\d+_.*\.png$/.test(name)) {
				fs.unlinkSync(path.join(artifactDir, name));
			}
		}
	}

	fs.writeFileSync(jsonFile, JSON.stringify(data, null, 2) + '\n', 'utf8');
}

const args = process.argv.slice(2);
if (args.length < 2) {
	usageAndExit();
}
const prefix = args[0];
for (let i = 1; i < args.length; ++i) {
	stripPrefix(args[i], prefix);
}
postprocessMarkdown(args[1]);
if (args.length >= 3) {
	prunePageImages(prefix, args[2]);
}
