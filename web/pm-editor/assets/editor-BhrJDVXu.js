import { C as EditorState, S as EditorView, _ as baseKeymap, a as insertVarText, b as redo, c as toggleBold, d as toggleUnderline, g as gapCursor, h as schema, i as insertVarTable, m as buildInputRules, n as insertVarImage, o as setHeading, p as nodeViews, r as insertVarRichtext, s as setParagraph, t as insertCustomText, u as toggleItalic, v as keymap, w as Plugin, x as undo, y as history } from "./commands-DW3W4uyt.js";
//#region src/editor-only.js
/**
* editor-only.js — ProseMirror editor for embedding in Flutter via iframe.
*
* Two modes:
*   'template' (default) — full authoring: insert variable nodes, custom blocks,
*                          format, headings. Everything is editable.
*   'report'            — preview of a resolved document. Only `custom_text`
*                          blocks are editable (free-text / manual inputs);
*                          all resolved variables are locked.
*
* postMessage protocol (Flutter → editor):
*   { type: 'SET_MODE', mode: 'template' | 'report' }       switch edit mode
*   { type: 'SET_DOC', doc: {...}, mode?: '...' }            load a document
*   { type: 'GET_DOC', id: '...' }                          request current doc
*   { type: 'INSERT_VAR_TEXT', ref: '...' }
*   { type: 'INSERT_VAR_RICHTEXT', ref: '...' }
*   { type: 'INSERT_VAR_IMAGE', ref: '...', caption: '...' }
*   { type: 'INSERT_VAR_TABLE', ref: '...', columns: [...], caption: '...' }
*   { type: 'INSERT_CUSTOM_TEXT', label: '...' }
*   { type: 'FORMAT_BOLD' | 'FORMAT_ITALIC' | 'FORMAT_UNDERLINE' }
*   { type: 'SET_HEADING', level: 1|2|3 }
*   { type: 'SET_PARAGRAPH' }
*   { type: 'UNDO' } | { type: 'REDO' }
*
* postMessage protocol (editor → Flutter/parent):
*   { type: 'EDITOR_READY' }
*   { type: 'DOC_CHANGED', doc: {...} }                     debounced 300ms
*   { type: 'DOC_RESULT', id: '...', doc: {...} }           reply to GET_DOC
*/
var reportModePlugin = new Plugin({ filterTransaction(tr, state) {
	if (!tr.docChanged) return true;
	let allowed = true;
	tr.steps.forEach((step) => {
		if (!allowed) return;
		if (typeof step.from !== "number") return;
		let startInside = false;
		let endInside = false;
		try {
			const $from = state.doc.resolve(step.from);
			for (let i = $from.depth; i > 0; i--) if ($from.node(i).type.name === "custom_text") startInside = true;
			const $to = state.doc.resolve(step.to ?? step.from);
			for (let i = $to.depth; i > 0; i--) if ($to.node(i).type.name === "custom_text") endInside = true;
		} catch {}
		if (!startInside || !endInside) allowed = false;
	});
	return allowed;
} });
function pluginsForMode(mode) {
	const base = [
		history(),
		keymap({
			"Mod-z": undo,
			"Mod-y": redo,
			"Mod-Shift-z": redo,
			"Mod-b": toggleBold,
			"Mod-i": toggleItalic,
			"Mod-u": toggleUnderline
		}),
		keymap(baseKeymap),
		gapCursor()
	];
	if (mode === "report") return [reportModePlugin, ...base];
	return [buildInputRules(), ...base];
}
var currentMode = "template";
function emit(msg) {
	const target = window.parent !== window ? window.parent : window.opener;
	if (target) target.postMessage(msg, "*");
}
var EMPTY_DOC = {
	type: "doc",
	content: [{
		type: "paragraph",
		content: []
	}]
};
var state = EditorState.create({
	doc: schema.nodeFromJSON(EMPTY_DOC),
	plugins: pluginsForMode(currentMode)
});
var _changeTimer = null;
var view = new EditorView(document.getElementById("editor-mount"), {
	state,
	nodeViews,
	dispatchTransaction(tr) {
		const newState = view.state.apply(tr);
		view.updateState(newState);
		if (tr.docChanged) {
			clearTimeout(_changeTimer);
			_changeTimer = setTimeout(() => {
				emit({
					type: "DOC_CHANGED",
					doc: view.state.doc.toJSON()
				});
			}, 300);
		}
	}
});
document.getElementById("btn-bold").addEventListener("click", () => {
	toggleBold(view.state, view.dispatch);
	view.focus();
});
document.getElementById("btn-italic").addEventListener("click", () => {
	toggleItalic(view.state, view.dispatch);
	view.focus();
});
document.getElementById("btn-underline").addEventListener("click", () => {
	toggleUnderline(view.state, view.dispatch);
	view.focus();
});
document.getElementById("btn-h1").addEventListener("click", () => {
	setHeading(1)(view.state, view.dispatch);
	view.focus();
});
document.getElementById("btn-h2").addEventListener("click", () => {
	setHeading(2)(view.state, view.dispatch);
	view.focus();
});
document.getElementById("btn-h3").addEventListener("click", () => {
	setHeading(3)(view.state, view.dispatch);
	view.focus();
});
document.getElementById("btn-para").addEventListener("click", () => {
	setParagraph(view.state, view.dispatch);
	view.focus();
});
document.getElementById("btn-undo").addEventListener("click", () => {
	undo(view.state, view.dispatch);
	view.focus();
});
document.getElementById("btn-redo").addEventListener("click", () => {
	redo(view.state, view.dispatch);
	view.focus();
});
window.addEventListener("message", (event) => {
	let msg = event.data;
	if (!msg) return;
	if (typeof msg === "string") try {
		msg = JSON.parse(msg);
	} catch {
		return;
	}
	if (typeof msg.type !== "string") return;
	switch (msg.type) {
		case "SET_MODE": {
			currentMode = msg.mode === "report" ? "report" : "template";
			const newState = EditorState.create({
				doc: view.state.doc,
				plugins: pluginsForMode(currentMode)
			});
			view.updateState(newState);
			break;
		}
		case "SET_DOC":
			try {
				if (typeof msg.mode === "string") currentMode = msg.mode === "report" ? "report" : "template";
				const doc = schema.nodeFromJSON(msg.doc ?? EMPTY_DOC);
				const newState = EditorState.create({
					doc,
					plugins: pluginsForMode(currentMode)
				});
				view.updateState(newState);
			} catch (e) {
				console.error("[editor-only] SET_DOC error:", e);
			}
			break;
		case "GET_DOC":
			emit({
				type: "DOC_RESULT",
				id: msg.id ?? null,
				doc: view.state.doc.toJSON()
			});
			break;
		case "INSERT_VAR_TEXT":
			if (msg.ref) {
				insertVarText(msg.ref)(view.state, view.dispatch);
				view.focus();
			}
			break;
		case "INSERT_VAR_RICHTEXT":
			if (msg.ref) {
				insertVarRichtext(msg.ref)(view.state, view.dispatch);
				view.focus();
			}
			break;
		case "INSERT_VAR_IMAGE":
			if (msg.ref) {
				insertVarImage(msg.ref, msg.caption ?? "")(view.state, view.dispatch);
				view.focus();
			}
			break;
		case "INSERT_VAR_TABLE":
			if (msg.ref) {
				const cols = Array.isArray(msg.columns) ? msg.columns : [];
				insertVarTable(msg.ref, cols, msg.caption ?? "")(view.state, view.dispatch);
				view.focus();
			}
			break;
		case "INSERT_CUSTOM_TEXT":
			insertCustomText(msg.label ?? "bloco")(view.state, view.dispatch);
			view.focus();
			break;
		case "FORMAT_BOLD":
			toggleBold(view.state, view.dispatch);
			view.focus();
			break;
		case "FORMAT_ITALIC":
			toggleItalic(view.state, view.dispatch);
			view.focus();
			break;
		case "FORMAT_UNDERLINE":
			toggleUnderline(view.state, view.dispatch);
			view.focus();
			break;
		case "SET_HEADING":
			setHeading(msg.level ?? 1)(view.state, view.dispatch);
			view.focus();
			break;
		case "SET_PARAGRAPH":
			setParagraph(view.state, view.dispatch);
			view.focus();
			break;
		case "UNDO":
			undo(view.state, view.dispatch);
			view.focus();
			break;
		case "REDO":
			redo(view.state, view.dispatch);
			view.focus();
			break;
	}
});
emit({ type: "EDITOR_READY" });
//#endregion
