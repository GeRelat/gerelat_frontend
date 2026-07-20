import { C as EditorState, S as EditorView, _ as baseKeymap, a as insertVarText, b as redo, c as toggleBold, d as toggleUnderline, f as wrapBlockquote, g as gapCursor, h as schema, i as insertVarTable, l as toggleCode, m as buildInputRules, n as insertVarImage, o as setHeading, p as nodeViews, r as insertVarRichtext, s as setParagraph, t as insertCustomText, u as toggleItalic, v as keymap, w as Plugin, x as undo, y as history } from "./commands-DW3W4uyt.js";
//#region src/panel.js
function getDocJson(state) {
	return JSON.stringify(state.doc.toJSON(), null, 2);
}
function highlightJson(json) {
	return json.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)/g, (match) => {
		let cls = "json-number";
		if (/^"/.test(match)) cls = /:$/.test(match) ? "json-key" : "json-string";
		else if (/true|false/.test(match)) cls = "json-bool";
		else if (/null/.test(match)) cls = "json-null";
		return `<span class="${cls}">${match}</span>`;
	});
}
function collectRefs(doc) {
	const seen = /* @__PURE__ */ new Set();
	const refs = [];
	doc.descendants((node) => {
		let entry = null;
		const nt = node.type.name;
		if (nt === "var_text" || nt === "variable") entry = {
			ref: node.attrs.ref,
			type: "text"
		};
		else if (nt === "var_richtext") entry = {
			ref: node.attrs.ref,
			type: "richtext"
		};
		else if (nt === "var_image" || nt === "image_ref") entry = {
			ref: node.attrs.ref,
			type: "image"
		};
		else if (nt === "var_table" || nt === "table_ref") entry = {
			ref: node.attrs.ref,
			type: "table"
		};
		else if (nt === "custom_text") entry = {
			ref: node.attrs.label,
			type: "custom"
		};
		if (entry) {
			const key = `${entry.type}::${entry.ref}`;
			if (!seen.has(key)) {
				seen.add(key);
				refs.push(entry);
			}
		}
	});
	return refs;
}
var TYPE_LABELS = {
	text: "text",
	richtext: "richtext",
	image: "image",
	table: "table",
	custom: "bloco livre"
};
function renderVarList(container, refs) {
	if (refs.length === 0) {
		container.innerHTML = `
      <div class="var-empty">
        <div style="font-size:28px; margin-bottom:8px">🔍</div>
        Nenhuma referência encontrada.<br>
        <span style="font-size:12px; color:#3a4060">Digite <code style="color:#818cf8">[entidade.campo]</code> para criar uma variável.</span>
      </div>`;
		return;
	}
	container.innerHTML = refs.map(({ ref, type }) => `
        <div class="var-item">
          <span class="var-item-ref">[${ref}]</span>
          <span class="var-item-type var-type-${type}">${TYPE_LABELS[type] ?? type}</span>
        </div>`).join("");
}
//#endregion
//#region src/modal.js
/**
* modal.js — Diálogos de inserção de nós especiais.
*/
function showModal({ title, description = "", fields }) {
	return new Promise((resolve) => {
		const overlay = document.createElement("div");
		overlay.className = "modal-overlay";
		const modal = document.createElement("div");
		modal.className = "modal";
		const h3 = document.createElement("h3");
		h3.textContent = title;
		modal.appendChild(h3);
		if (description) {
			const p = document.createElement("p");
			p.textContent = description;
			modal.appendChild(p);
		}
		const inputs = {};
		fields.forEach(({ id, label, placeholder = "", hint = "", type = "text", value = "" }) => {
			const fieldDiv = document.createElement("div");
			fieldDiv.className = "modal-field";
			const lbl = document.createElement("label");
			lbl.setAttribute("for", `modal-${id}`);
			lbl.textContent = label;
			fieldDiv.appendChild(lbl);
			let input;
			if (type === "textarea") {
				input = document.createElement("textarea");
				input.rows = 3;
			} else {
				input = document.createElement("input");
				input.type = type;
			}
			input.id = `modal-${id}`;
			input.placeholder = placeholder;
			input.value = value;
			fieldDiv.appendChild(input);
			inputs[id] = input;
			if (hint) {
				const hintEl = document.createElement("div");
				hintEl.className = "modal-hint";
				hintEl.textContent = hint;
				fieldDiv.appendChild(hintEl);
			}
			modal.appendChild(fieldDiv);
		});
		const actions = document.createElement("div");
		actions.className = "modal-actions";
		const cancelBtn = document.createElement("button");
		cancelBtn.className = "btn btn-ghost";
		cancelBtn.textContent = "Cancelar";
		const confirmBtn = document.createElement("button");
		confirmBtn.className = "btn btn-primary";
		confirmBtn.textContent = "Inserir";
		actions.appendChild(cancelBtn);
		actions.appendChild(confirmBtn);
		modal.appendChild(actions);
		overlay.appendChild(modal);
		document.body.appendChild(overlay);
		requestAnimationFrame(() => Object.values(inputs)[0]?.focus());
		const submit = () => {
			const result = {};
			for (const [key, el] of Object.entries(inputs)) result[key] = el.value.trim();
			overlay.remove();
			resolve(result);
		};
		const cancel = () => {
			overlay.remove();
			resolve(null);
		};
		Object.values(inputs).forEach((input) => {
			input.addEventListener("keydown", (e) => {
				if (e.key === "Enter" && input.tagName !== "TEXTAREA") submit();
				if (e.key === "Escape") cancel();
			});
		});
		confirmBtn.addEventListener("click", submit);
		cancelBtn.addEventListener("click", cancel);
		overlay.addEventListener("click", (e) => {
			if (e.target === overlay) cancel();
		});
	});
}
async function modalVarText() {
	return showModal({
		title: "⟨T⟩ Variável texto",
		description: "Insere inline a referência de uma variável do tipo text.",
		fields: [{
			id: "ref",
			label: "Referência",
			placeholder: "nome_evento",
			hint: "Deve corresponder exatamente ao campo \"referência\" no cadastro de variáveis."
		}]
	});
}
async function modalVarRichtext() {
	return showModal({
		title: "📄 Variável richtext",
		description: "Insere um bloco que será preenchido por uma variável do tipo richtext.",
		fields: [{
			id: "ref",
			label: "Referência",
			placeholder: "objetivo_evento",
			hint: "Deve corresponder ao campo \"referência\" de uma variável tipo richtext."
		}]
	});
}
async function modalVarImage() {
	return showModal({
		title: "🖼 Variável imagem",
		description: "Insere um bloco que será preenchido por uma variável do tipo image.",
		fields: [{
			id: "ref",
			label: "Referência",
			placeholder: "foto_turma",
			hint: "Deve corresponder ao campo \"referência\" de uma variável tipo image."
		}, {
			id: "caption",
			label: "Legenda (opcional)",
			placeholder: "Foto da turma do evento"
		}]
	});
}
async function modalVarTable() {
	return showModal({
		title: "📊 Variável tabela",
		description: "Insere um bloco que será preenchido por uma variável do tipo table.",
		fields: [
			{
				id: "ref",
				label: "Referência",
				placeholder: "lista_participantes",
				hint: "Deve corresponder ao campo \"referência\" de uma variável tipo table."
			},
			{
				id: "columns",
				label: "Colunas (separadas por vírgula)",
				placeholder: "nome, cpf, presença",
				hint: "Apenas para preview no editor — as colunas reais vêm do valor da variável."
			},
			{
				id: "caption",
				label: "Legenda (opcional)",
				placeholder: "Participantes do evento"
			}
		]
	});
}
async function modalCustomText() {
	return showModal({
		title: "📝 Bloco de texto livre",
		description: "Insere um bloco editável sem referência de variável — o usuário escreve diretamente no relatório.",
		fields: [{
			id: "label",
			label: "Nome do bloco",
			placeholder: "observacoes",
			hint: "Identificador visual. Não vinculado a nenhuma variável."
		}]
	});
}
//#endregion
//#region src/api.js
/**
* api.js — GeRelat API client
*/
function getBase() {
	return localStorage.getItem("gerelat_api_base") || "http://localhost:8000";
}
function getProjetoId() {
	return parseInt(localStorage.getItem("gerelat_projeto_id") || "1", 10);
}
function getAccessToken() {
	return localStorage.getItem("gerelat_access_token") || "";
}
function getRefreshToken() {
	return localStorage.getItem("gerelat_refresh_token") || "";
}
function saveConfig(base, projetoId) {
	localStorage.setItem("gerelat_api_base", base.replace(/\/$/, ""));
	localStorage.setItem("gerelat_projeto_id", String(projetoId));
}
function saveAuthTokens({ access, refresh }) {
	if (access !== void 0) localStorage.setItem("gerelat_access_token", access || "");
	if (refresh !== void 0) localStorage.setItem("gerelat_refresh_token", refresh || "");
}
function clearAuthTokens() {
	localStorage.removeItem("gerelat_access_token");
	localStorage.removeItem("gerelat_refresh_token");
}
async function loginWithCredentials(email, password) {
	const res = await fetch(getBase() + "/auth/login/", {
		method: "POST",
		headers: { "Content-Type": "application/json" },
		body: JSON.stringify({
			email,
			password
		})
	});
	const data = await res.json().catch(() => ({}));
	if (!res.ok) throw new Error(data.detail || "Falha ao autenticar.");
	if (!data.access || !data.refresh) throw new Error("Resposta de autenticação inválida.");
	saveAuthTokens({
		access: data.access,
		refresh: data.refresh
	});
	return data;
}
async function refreshAccessToken() {
	const refresh = getRefreshToken();
	if (!refresh) return false;
	const res = await fetch(getBase() + "/auth/login/refresh/", {
		method: "POST",
		headers: { "Content-Type": "application/json" },
		body: JSON.stringify({ refresh })
	});
	const data = await res.json().catch(() => ({}));
	if (!res.ok || !data.access) return false;
	saveAuthTokens({
		access: data.access,
		refresh: data.refresh ?? refresh
	});
	return true;
}
async function authFetch(url, opts = {}, retry = true) {
	const headers = { ...opts.headers || {} };
	const access = getAccessToken();
	if (access) headers.Authorization = `Bearer ${access}`;
	const res = await fetch(url, {
		...opts,
		headers
	});
	if (res.status !== 401 || !retry) return res;
	if (!await refreshAccessToken()) return res;
	const nextHeaders = {
		...opts.headers || {},
		Authorization: `Bearer ${getAccessToken()}`
	};
	return fetch(url, {
		...opts,
		headers: nextHeaders
	});
}
async function req(method, path, body) {
	const opts = {
		method,
		headers: {}
	};
	if (body !== void 0) {
		opts.headers["Content-Type"] = "application/json";
		opts.body = JSON.stringify(body);
	}
	const res = await authFetch(getBase() + path, opts);
	if (!res.ok) {
		const err = await res.json().catch(() => ({}));
		throw new Error(err.detail || JSON.stringify(err) || `HTTP ${res.status}`);
	}
	return res.status === 204 ? null : res.json();
}
var api = {
	getCampos: () => req("GET", `/projeto-campos/?projeto=${getProjetoId()}`),
	createCampo: (data) => req("POST", "/projeto-campos/", data),
	updateCampo: (id, data) => req("PUT", `/projeto-campos/${id}/`, data),
	deleteCampo: (id) => req("DELETE", `/projeto-campos/${id}/`),
	getTemplates: () => req("GET", "/templates/"),
	getTemplatePreview: (id, qs = "") => req("GET", `/templates/${id}/preview/${qs}`),
	createTemplateFromJson: (data) => req("POST", "/templates/", data),
	updateTemplateJson: (id, modelo_json) => req("PATCH", `/templates/${id}/`, { modelo_json }),
	convertDocx: (file) => {
		const form = new FormData();
		form.append("arquivo", file);
		return authFetch(`${getBase()}/templates/convert-docx/`, {
			method: "POST",
			body: form
		}).then(async (res) => {
			if (!res.ok) {
				const err = await res.json().catch(() => ({}));
				throw new Error(err.detail || `HTTP ${res.status}`);
			}
			return res.json();
		});
	},
	getRelatorios: () => req("GET", "/relatorios/"),
	generateRelatorio: (templateId, eventoId, documentoJson = null, nome = null) => req("POST", "/relatorios/", Object.assign({ template: templateId }, ...eventoId ? [{ evento: eventoId }] : [], ...documentoJson ? [{ documento_json: documentoJson }] : [], ...nome ? [{ nome }] : [])),
	downloadRelatorio: (id) => {
		return authFetch(`${getBase()}/relatorios/${id}/download/`);
	},
	loginWithCredentials,
	logout: async () => {
		const refresh = getRefreshToken();
		if (refresh) await authFetch(getBase() + "/auth/logout/", {
			method: "POST",
			headers: { "Content-Type": "application/json" },
			body: JSON.stringify({ refresh })
		}, false).catch(() => {});
		clearAuthTokens();
	},
	getTaskStatus: (taskId) => req("GET", `/tasks/${taskId}/`),
	pollTask: async (taskId, options = {}) => {
		const intervalMs = options.intervalMs ?? 1e3;
		const timeoutMs = options.timeoutMs ?? 12e4;
		const deadline = Date.now() + timeoutMs;
		while (true) {
			const status = await (async () => {
				try {
					return await api.getTaskStatus(taskId);
				} catch (err) {
					throw err;
				}
			})();
			const state = status.task_status;
			if (state === "SUCCESS") return status;
			if (state === "FAILURE") throw new Error(status.error || "Task failed");
			if (Date.now() > deadline) throw new Error("Task polling timed out");
			await new Promise((resolve) => setTimeout(resolve, intervalMs));
		}
	}
};
//#endregion
//#region src/pages/variables.js
/**
* variables.js — Variables (ProjetoCampo) management page
*/
function textToProseDoc(text) {
	return {
		type: "doc",
		content: [{
			type: "paragraph",
			content: [{
				type: "text",
				text: text || " "
			}]
		}]
	};
}
function extractText(valor) {
	try {
		return (valor?.content ?? []).flatMap((block) => block.content ?? []).filter((n) => n.type === "text").map((n) => n.text).join("");
	} catch {
		return "";
	}
}
function buildValorFromForm(tipo) {
	if (tipo === "text" || tipo === "richtext") {
		const text = document.getElementById("val-text").value.trim();
		if (!text) throw new Error("Valor não pode ser vazio.");
		return textToProseDoc(text);
	}
	if (tipo === "image") {
		const assetId = parseInt(document.getElementById("val-asset-id").value, 10);
		if (!assetId || assetId <= 0) throw new Error("asset_id inválido.");
		return {
			asset_id: assetId,
			width_mm: parseFloat(document.getElementById("val-width").value) || null,
			height_mm: parseFloat(document.getElementById("val-height").value) || null,
			caption: document.getElementById("val-caption").value.trim() || null
		};
	}
	if (tipo === "table") {
		const colsRaw = document.getElementById("val-cols").value.trim();
		const rowsRaw = document.getElementById("val-rows").value.trim();
		if (!colsRaw) throw new Error("Colunas obrigatórias.");
		const columns = colsRaw.split(",").map((c) => {
			const [key, label] = c.trim().split(":").map((s) => s.trim());
			return {
				key,
				label: label || key
			};
		});
		let rows = [];
		if (rowsRaw) try {
			rows = JSON.parse(rowsRaw);
		} catch {
			throw new Error("Linhas devem ser JSON válido. Ex: [{\"col\":\"val\"}]");
		}
		return {
			columns,
			rows
		};
	}
	throw new Error("Tipo inválido.");
}
function loadValorIntoForm(tipo, valor) {
	if (!valor) return;
	if (tipo === "text" || tipo === "richtext") {
		const el = document.getElementById("val-text");
		if (el) el.value = extractText(valor);
	}
	if (tipo === "image") {
		if (document.getElementById("val-asset-id")) {
			document.getElementById("val-asset-id").value = valor.asset_id ?? "";
			document.getElementById("val-width").value = valor.width_mm ?? "";
			document.getElementById("val-height").value = valor.height_mm ?? "";
			document.getElementById("val-caption").value = valor.caption ?? "";
		}
	}
	if (tipo === "table") {
		if (document.getElementById("val-cols")) {
			const cols = (valor.columns ?? []).map((c) => c.key === c.label ? c.key : `${c.key}:${c.label}`).join(", ");
			document.getElementById("val-cols").value = cols;
			document.getElementById("val-rows").value = valor.rows?.length ? JSON.stringify(valor.rows, null, 2) : "";
		}
	}
}
function valorPreview(tipo, valor) {
	if (!valor) return "—";
	if (tipo === "text" || tipo === "richtext") return extractText(valor) || "—";
	if (tipo === "image") return `Asset #${valor.asset_id}`;
	if (tipo === "table") return `${valor.columns?.length ?? 0} coluna(s), ${valor.rows?.length ?? 0} linha(s)`;
	return "—";
}
function renderValorFields(tipo) {
	if (tipo === "text" || tipo === "richtext") return `
      <div class="form-group">
        <label>Valor (texto)</label>
        <textarea id="val-text" class="form-input" rows="3" placeholder="Conteúdo do campo"></textarea>
      </div>`;
	if (tipo === "image") return `
      <div class="form-group">
        <label>Asset ID <span class="required">*</span></label>
        <input id="val-asset-id" type="number" class="form-input" min="1" placeholder="ID do asset" />
      </div>
      <div class="form-row">
        <div class="form-group">
          <label>Largura (mm)</label>
          <input id="val-width" type="number" class="form-input" step="0.1" placeholder="ex: 80" />
        </div>
        <div class="form-group">
          <label>Altura (mm)</label>
          <input id="val-height" type="number" class="form-input" step="0.1" placeholder="auto" />
        </div>
      </div>
      <div class="form-group">
        <label>Legenda</label>
        <input id="val-caption" type="text" class="form-input" placeholder="Legenda opcional" />
      </div>`;
	if (tipo === "table") return `
      <div class="form-group">
        <label>Colunas <span class="required">*</span></label>
        <input id="val-cols" type="text" class="form-input" placeholder="nome, idade:Idade, cidade" />
        <small>Formato: chave ou chave:Label, separadas por vírgula</small>
      </div>
      <div class="form-group">
        <label>Linhas (JSON)</label>
        <textarea id="val-rows" class="form-input" rows="4" placeholder='[{"nome":"Ana","idade":20}]'></textarea>
      </div>`;
	return "";
}
var VariablesPage = class {
	constructor(showToast) {
		this.showToast = showToast;
		this.campos = [];
		this.editingId = null;
		this._mounted = false;
	}
	async init(container) {
		this.container = container;
		this._render();
		this._mounted = true;
		await this._loadCampos();
	}
	_render() {
		this.container.innerHTML = `
      <div class="page-content">
        <div class="page-main">
          <div class="section-header">
            <h2>Variáveis do Projeto</h2>
            <span class="badge">Projeto #${getProjetoId()}</span>
            <button id="btn-refresh-campos" class="btn btn-ghost btn-sm" style="margin-left:auto">↻ Atualizar</button>
          </div>
          <p class="page-desc">
            As variáveis devem usar a mesma <strong>referência</strong> que o placeholder no template DOCX
            (<code>{{ referencia }}</code>).
          </p>
          <div id="campos-list" class="campos-list">
            <div class="loading">Carregando...</div>
          </div>
        </div>

        <div class="page-side">
          <div class="card">
            <div class="card-title" id="form-title">Adicionar Variável</div>
            <form id="campo-form">
              <div class="form-group">
                <label>Referência <span class="required">*</span></label>
                <input id="campo-ref" type="text" class="form-input" placeholder="ex: nome_responsavel" />
                <small>Sem espaços. Deve corresponder ao placeholder no template.</small>
              </div>
              <div class="form-group">
                <label>Tipo <span class="required">*</span></label>
                <select id="campo-tipo" class="form-input">
                  <option value="text">Texto</option>
                  <option value="richtext">Texto Rico</option>
                  <option value="image">Imagem</option>
                  <option value="table">Tabela</option>
                </select>
              </div>
              <div class="form-group">
                <label>Descrição</label>
                <textarea id="campo-descricao" class="form-input" rows="2" placeholder="Descrição/observações"></textarea>
                <small>Texto livre associado à variável</small>
              </div>
              <div id="valor-fields">${renderValorFields("text")}</div>
              <div class="form-actions">
                <button type="submit" class="btn btn-primary" id="btn-submit-campo">Adicionar</button>
                <button type="button" class="btn btn-ghost" id="btn-cancel-edit" style="display:none">Cancelar</button>
              </div>
            </form>
          </div>
        </div>
      </div>
    `;
		document.getElementById("campo-tipo").addEventListener("change", (e) => {
			document.getElementById("valor-fields").innerHTML = renderValorFields(e.target.value);
		});
		document.getElementById("campo-form").addEventListener("submit", (e) => {
			e.preventDefault();
			this._submitForm();
		});
		document.getElementById("btn-cancel-edit").addEventListener("click", () => this._cancelEdit());
		document.getElementById("btn-refresh-campos").addEventListener("click", () => this._loadCampos());
	}
	async _loadCampos() {
		const listEl = document.getElementById("campos-list");
		if (!listEl) return;
		listEl.innerHTML = "<div class=\"loading\">Carregando...</div>";
		try {
			const data = await api.getCampos();
			this.campos = data.results ?? data;
			this._renderList();
		} catch (err) {
			if (document.getElementById("campos-list")) document.getElementById("campos-list").innerHTML = `<div class="error-msg">Erro ao carregar: ${err.message}</div>`;
		}
	}
	_renderList() {
		const listEl = document.getElementById("campos-list");
		if (!listEl) return;
		if (!this.campos.length) {
			listEl.innerHTML = "<div class=\"empty-msg\">Nenhuma variável cadastrada para este projeto.</div>";
			return;
		}
		listEl.innerHTML = this.campos.map((c) => `
      <div class="campo-card">
        <div class="campo-ref"><code>{{ ${c.referencia} }}</code></div>
        <div class="campo-meta">
          <span class="badge badge-tipo badge-${c.tipo}">${c.tipo}</span>
          <span class="campo-preview">${valorPreview(c.tipo, c.valor)}</span>
        </div>
        <div class="campo-actions">
          <button class="btn btn-ghost btn-sm btn-edit-campo" data-id="${c.id_campo}">✏️ Editar</button>
          <button class="btn btn-danger btn-sm btn-del-campo" data-id="${c.id_campo}">🗑️</button>
        </div>
      </div>
    `).join("");
		listEl.querySelectorAll(".btn-del-campo").forEach((btn) => {
			btn.addEventListener("click", () => this._deleteCampo(parseInt(btn.dataset.id, 10)));
		});
		listEl.querySelectorAll(".btn-edit-campo").forEach((btn) => {
			btn.addEventListener("click", () => this._startEdit(parseInt(btn.dataset.id, 10)));
		});
	}
	_startEdit(id) {
		const campo = this.campos.find((c) => c.id_campo === id);
		if (!campo) return;
		this.editingId = id;
		document.getElementById("form-title").textContent = "Editar Variável";
		document.getElementById("campo-ref").value = campo.referencia;
		const tipoEl = document.getElementById("campo-tipo");
		tipoEl.value = campo.tipo;
		document.getElementById("valor-fields").innerHTML = renderValorFields(campo.tipo);
		loadValorIntoForm(campo.tipo, campo.valor);
		document.getElementById("btn-submit-campo").textContent = "Salvar";
		document.getElementById("btn-cancel-edit").style.display = "";
		document.getElementById("campo-ref").focus();
		const descEl = document.getElementById("campo-descricao");
		if (descEl) descEl.value = campo.descricao || "";
	}
	_cancelEdit() {
		this.editingId = null;
		document.getElementById("form-title").textContent = "Adicionar Variável";
		document.getElementById("campo-ref").value = "";
		document.getElementById("campo-tipo").value = "text";
		document.getElementById("valor-fields").innerHTML = renderValorFields("text");
		document.getElementById("btn-submit-campo").textContent = "Adicionar";
		document.getElementById("btn-cancel-edit").style.display = "none";
		const descEl = document.getElementById("campo-descricao");
		if (descEl) descEl.value = "";
	}
	async _submitForm() {
		const referencia = document.getElementById("campo-ref").value.trim();
		const tipo = document.getElementById("campo-tipo").value;
		if (!referencia) {
			this.showToast("Referência obrigatória.", "error");
			return;
		}
		let valor;
		try {
			valor = buildValorFromForm(tipo);
		} catch (err) {
			this.showToast(err.message, "error");
			return;
		}
		const descricao = (document.getElementById("campo-descricao")?.value || "").trim();
		const payload = {
			referencia,
			tipo,
			valor,
			projeto: getProjetoId(),
			descricao
		};
		const btn = document.getElementById("btn-submit-campo");
		btn.disabled = true;
		try {
			if (this.editingId) {
				await api.updateCampo(this.editingId, payload);
				this.showToast("Variável atualizada.");
				this._cancelEdit();
			} else {
				await api.createCampo(payload);
				this.showToast("Variável criada.");
				document.getElementById("campo-ref").value = "";
				const valText = document.getElementById("val-text");
				if (valText) valText.value = "";
			}
			await this._loadCampos();
		} catch (err) {
			this.showToast(`Erro: ${err.message}`, "error");
		} finally {
			btn.disabled = false;
		}
	}
	async _deleteCampo(id) {
		if (!confirm("Excluir esta variável?")) return;
		try {
			await api.deleteCampo(id);
			this.showToast("Variável excluída.");
			await this._loadCampos();
		} catch (err) {
			this.showToast(`Erro: ${err.message}`, "error");
		}
	}
};
//#endregion
//#region src/pages/reports.js
/**
* reports.js — Geração de relatórios com preview editável
*
* Fluxo:
*  1. Selecionar template + evento opcional → "Visualizar Preview"
*  2. API resolve variáveis → documento_json carregado em editor ProseMirror
*     (somente custom_text é editável)
*  3. "Gerar Relatório Definitivo" envia documento_json editado → POST /relatorios/
*  4. Lista de relatórios com botão de download
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
var ReportsPage = class {
	constructor(showToast) {
		this.showToast = showToast;
		this.templates = [];
		this.relatorios = [];
		this._previewView = null;
		this._previewTemplateId = null;
		this._previewEventoId = null;
	}
	async init(container) {
		this.container = container;
		this._render();
		await Promise.all([this._loadTemplates(), this._loadRelatorios()]);
	}
	_render() {
		if (this._previewView) {
			this._previewView.destroy();
			this._previewView = null;
		}
		this.container.innerHTML = `
      <div class="reports-layout">

        <!-- Coluna esquerda: formulário + lista -->
        <div class="reports-left">
          <div class="section-header">
            <h2>Relatórios</h2>
            <button id="btn-refresh-relatorios" class="btn btn-ghost btn-sm" style="margin-left:auto">↻</button>
          </div>

          <!-- Formulário de seleção -->
          <div class="card" style="margin-bottom:14px">
            <div class="card-title">Novo Relatório</div>
            <div class="form-group">
              <label>Template <span class="required">*</span></label>
              <select id="select-template" class="form-input">
                <option value="">Carregando…</option>
              </select>
            </div>
            <div class="form-group">
              <label>ID do Evento <small>(opcional)</small></label>
              <input id="input-evento" type="number" class="form-input" min="1" placeholder="Deixar vazio para ignorar" />
            </div>
            <div class="form-group">
              <label>Nome do Relatório <small>(opcional)</small></label>
              <input id="input-nome-relatorio" type="text" class="form-input" placeholder="Opcional: nome amigável para o arquivo" />
            </div>
            <button id="btn-preview" class="btn btn-primary" style="width:100%">
              👁 Visualizar Preview
            </button>
          </div>

          <!-- Lista de relatórios -->
          <div class="section-header" style="margin-top:4px; display:flex; align-items:center; gap:8px">
            <h3 style="font-size:14px;font-weight:600; margin:0">Relatórios Gerados</h3>
            <button id="btn-refresh-relatorios" class="btn btn-ghost btn-sm" style="margin-left:auto">↻</button>
          </div>
          <div id="relatorios-list" class="relatorios-list">
            <div class="loading">Carregando…</div>
          </div>
        </div>

        <!-- Coluna direita: preview editor (inicialmente vazio) -->
        <div class="reports-right" id="preview-panel">
          <div class="preview-empty">
            <div style="font-size:32px;margin-bottom:12px">📄</div>
            <p>Selecione um template e clique em<br><strong>Visualizar Preview</strong> para ver o documento com as variáveis preenchidas.</p>
            <p style="margin-top:8px;font-size:12px;color:var(--text-muted)">Os blocos de texto personalizados (destacados) poderão ser editados antes de gerar.</p>
          </div>
        </div>

      </div>
    `;
		document.getElementById("btn-preview").addEventListener("click", () => this._loadPreview());
		Array.from(document.querySelectorAll("#btn-refresh-relatorios")).forEach((btn) => btn.addEventListener("click", () => this.refreshRelatorios()));
	}
	async _loadTemplates() {
		const sel = document.getElementById("select-template");
		if (!sel) return;
		try {
			const data = await api.getTemplates();
			this.templates = data.results ?? data;
			if (!this.templates.length) {
				sel.innerHTML = "<option value=\"\">Nenhum template cadastrado</option>";
				return;
			}
			sel.innerHTML = this.templates.map((t) => `<option value="${t.id}">${t.nome} (#${t.id})</option>`).join("");
		} catch (err) {
			if (document.getElementById("select-template")) document.getElementById("select-template").innerHTML = "<option value=\"\">Erro ao carregar</option>";
		}
	}
	async _loadRelatorios() {
		const listEl = document.getElementById("relatorios-list");
		if (!listEl) return;
		listEl.innerHTML = "<div class=\"loading\">Carregando…</div>";
		try {
			const data = await api.getRelatorios();
			this.relatorios = data.results ?? data;
			this._renderList();
		} catch (err) {
			if (document.getElementById("relatorios-list")) document.getElementById("relatorios-list").innerHTML = `<div class="error-msg">Erro: ${err.message}</div>`;
		}
	}
	async refreshRelatorios() {
		try {
			this.showToast("Atualizando relatórios…", "info");
			await this._loadRelatorios();
			this.showToast("Lista de relatórios atualizada.", "success");
		} catch (err) {
			this.showToast(`Erro ao atualizar: ${err.message}`, "error");
		}
	}
	_renderList() {
		const listEl = document.getElementById("relatorios-list");
		if (!listEl) return;
		if (!this.relatorios.length) {
			listEl.innerHTML = "<div class=\"empty-msg\">Nenhum relatório gerado ainda.</div>";
			return;
		}
		listEl.innerHTML = [...this.relatorios].sort((a, b) => b.id - a.id).map((r) => {
			const date = new Date(r.data_criacao).toLocaleString("pt-BR");
			const cls = r.status === "SUCCESS" ? "success" : r.status === "FAILURE" ? "error" : "pending";
			return `
        <div class="relatorio-card">
          <div class="relatorio-header">
            <span class="relatorio-nome">${r.nome || `Relatório #${r.id}`}</span>
            <span class="badge badge-status badge-${cls}">${r.status}</span>
          </div>
          <div class="relatorio-meta">
            Template #${r.template}${r.evento ? ` · Evento #${r.evento}` : ""} · ${date}
          </div>
          <div class="relatorio-actions">
            <button class="btn btn-primary btn-sm btn-download-rel" data-id="${r.id}">⬇ Baixar DOCX</button>
          </div>
        </div>
      `;
		}).join("");
		listEl.querySelectorAll(".btn-download-rel").forEach((btn) => {
			btn.addEventListener("click", () => this._downloadRelatorio(parseInt(btn.dataset.id, 10)));
		});
	}
	async _loadPreview() {
		const templateId = parseInt(document.getElementById("select-template")?.value || "0", 10);
		if (!templateId) {
			this.showToast("Selecione um template.", "error");
			return;
		}
		const eventoRaw = document.getElementById("input-evento")?.value.trim();
		const eventoId = eventoRaw ? parseInt(eventoRaw, 10) : null;
		const btn = document.getElementById("btn-preview");
		btn.disabled = true;
		btn.textContent = "⏳ Carregando…";
		try {
			const qs = eventoId ? `?evento_id=${eventoId}` : "";
			const result = await api.getTemplatePreview(templateId, qs);
			this._previewTemplateId = templateId;
			this._previewEventoId = eventoId;
			this._mountPreviewEditor(result.documento_json);
		} catch (err) {
			this.showToast(`Erro ao carregar preview: ${err.message}`, "error");
		} finally {
			btn.disabled = false;
			btn.textContent = "👁 Visualizar Preview";
		}
	}
	_mountPreviewEditor(documentoJson) {
		const panel = document.getElementById("preview-panel");
		if (!panel) return;
		if (this._previewView) {
			this._previewView.destroy();
			this._previewView = null;
		}
		panel.innerHTML = `
      <div class="preview-header">
        <div>
          <div class="preview-title">Preview do Documento</div>
          <div class="preview-hint">
            Blocos <span class="hint-badge">📝 texto personalizado</span> são editáveis.
            Os demais campos estão bloqueados.
          </div>
        </div>
        <div style="display:flex;gap:8px;align-items:center">
          <div class="preview-toolbar" id="preview-toolbar">
            <button id="pvw-bold"      class="btn btn-fmt btn-ghost btn-sm"><b>B</b></button>
            <button id="pvw-italic"    class="btn btn-fmt btn-ghost btn-sm"><i>I</i></button>
            <button id="pvw-underline" class="btn btn-fmt btn-ghost btn-sm"><u>U</u></button>
          </div>
          <button id="btn-gerar-definitivo" class="btn btn-primary">
            ✅ Gerar Relatório Definitivo
          </button>
        </div>
      </div>
      <div class="preview-body">
        <div class="editor-paper preview-paper">
          <div id="preview-editor-mount"></div>
        </div>
      </div>
    `;
		let doc;
		try {
			doc = schema.nodeFromJSON(documentoJson);
		} catch (err) {
			panel.innerHTML = `<div class="error-msg">Erro ao carregar documento: ${err.message}</div>`;
			return;
		}
		const state = EditorState.create({
			doc,
			plugins: [
				reportModePlugin,
				history(),
				keymap({
					"Mod-z": undo,
					"Mod-y": redo,
					"Mod-Shift-z": redo,
					"Mod-b": toggleBold,
					"Mod-i": toggleItalic,
					"Mod-u": toggleUnderline
				}),
				keymap(baseKeymap)
			]
		});
		this._previewView = new EditorView(document.getElementById("preview-editor-mount"), {
			state,
			nodeViews
		});
		document.getElementById("pvw-bold").addEventListener("click", () => {
			toggleBold(this._previewView.state, this._previewView.dispatch);
			this._previewView.focus();
		});
		document.getElementById("pvw-italic").addEventListener("click", () => {
			toggleItalic(this._previewView.state, this._previewView.dispatch);
			this._previewView.focus();
		});
		document.getElementById("pvw-underline").addEventListener("click", () => {
			toggleUnderline(this._previewView.state, this._previewView.dispatch);
			this._previewView.focus();
		});
		document.getElementById("btn-gerar-definitivo").addEventListener("click", () => {
			this._gerarDefinitivo();
		});
	}
	async _gerarDefinitivo() {
		if (!this._previewView) return;
		const btn = document.getElementById("btn-gerar-definitivo");
		btn.disabled = true;
		btn.textContent = "⏳ Gerando…";
		try {
			const documento_json = this._previewView.state.doc.toJSON();
			const nomeRelatorio = (document.getElementById("input-nome-relatorio")?.value || "").trim();
			const taskResp = await api.generateRelatorio(this._previewTemplateId, this._previewEventoId, documento_json, nomeRelatorio || null);
			try {
				const taskResult = (await api.pollTask(taskResp.task_id)).result;
				if (taskResult && taskResult.type === "Relatorio" && taskResult.id) {
					await this._loadRelatorios();
					btn.disabled = false;
					btn.textContent = "✅ Gerar Relatório Definitivo";
					this.showToast(`Relatório #${taskResult.id} gerado!`, "success", 4e3);
					return;
				}
				await this._loadRelatorios();
				btn.disabled = false;
				btn.textContent = "✅ Gerar Relatório Definitivo";
				this.showToast("Relatório gerado com sucesso.", "success", 4e3);
			} catch (err) {
				this.showToast(`Erro ao processar task: ${err.message}`, "error");
				btn.disabled = false;
				btn.textContent = "✅ Gerar Relatório Definitivo";
			}
		} catch (err) {
			this.showToast(`Erro: ${err.message}`, "error");
			btn.disabled = false;
			btn.textContent = "✅ Gerar Relatório Definitivo";
		}
	}
	async _downloadRelatorio(id) {
		try {
			const res = await api.downloadRelatorio(id);
			if (!res.ok) {
				const err = await res.json().catch(() => ({}));
				throw new Error(err.detail || `HTTP ${res.status}`);
			}
			const blob = await res.blob();
			const url = URL.createObjectURL(blob);
			const a = document.createElement("a");
			a.href = url;
			a.download = `relatorio-${id}.docx`;
			a.click();
			URL.revokeObjectURL(url);
			this.showToast("Download iniciado.");
		} catch (err) {
			this.showToast(`Erro ao baixar: ${err.message}`, "error");
		}
	}
};
//#endregion
//#region src/main.js
function showToast(message, type = "success", durationMs = 2500) {
	const icons = {
		success: "✅",
		error: "❌",
		info: "ℹ️"
	};
	const toast = document.createElement("div");
	toast.className = `toast ${type}`;
	toast.innerHTML = `<span>${icons[type] ?? ""}</span><span>${message}</span>`;
	document.body.appendChild(toast);
	setTimeout(() => {
		toast.style.opacity = "0";
		setTimeout(() => toast.remove(), 300);
	}, durationMs);
}
var variablesPage = new VariablesPage(showToast);
var reportsPage = new ReportsPage(showToast);
var INITIAL_DOC = {
	"type": "doc",
	"content": [
		{
			"type": "heading",
			"attrs": { "level": 1 },
			"content": [{
				"type": "text",
				"text": "RELATÓRIO DE ATIVIDADE"
			}]
		},
		{
			"type": "paragraph",
			"content": [
				{
					"type": "text",
					"text": "Contrato nº "
				},
				{
					"type": "var_text",
					"attrs": { "ref": "numero_contrato" }
				},
				{
					"type": "text",
					"text": " — Parceria com "
				},
				{
					"type": "var_text",
					"attrs": { "ref": "nome_parceira" }
				}
			]
		},
		{
			"type": "heading",
			"attrs": { "level": 2 },
			"content": [{
				"type": "text",
				"text": "1. Identificação da Atividade"
			}]
		},
		{
			"type": "paragraph",
			"content": [{
				"type": "text",
				"text": "Atividade: ",
				"marks": [{ "type": "strong" }]
			}, {
				"type": "var_text",
				"attrs": { "ref": "nome_evento" }
			}]
		},
		{
			"type": "paragraph",
			"content": [{
				"type": "text",
				"text": "Data: ",
				"marks": [{ "type": "strong" }]
			}, {
				"type": "var_text",
				"attrs": { "ref": "data_evento" }
			}]
		},
		{
			"type": "paragraph",
			"content": [
				{
					"type": "text",
					"text": "Local: ",
					"marks": [{ "type": "strong" }]
				},
				{
					"type": "var_text",
					"attrs": { "ref": "local_evento" }
				},
				{
					"type": "text",
					"text": " — "
				},
				{
					"type": "var_text",
					"attrs": { "ref": "endereco_evento" }
				}
			]
		},
		{
			"type": "paragraph",
			"content": [{
				"type": "text",
				"text": "Carga horária: ",
				"marks": [{ "type": "strong" }]
			}, {
				"type": "var_text",
				"attrs": { "ref": "carga_horaria" }
			}]
		},
		{
			"type": "paragraph",
			"content": [{
				"type": "text",
				"text": "Total de participantes: ",
				"marks": [{ "type": "strong" }]
			}, {
				"type": "var_text",
				"attrs": { "ref": "total_participantes" }
			}]
		},
		{
			"type": "heading",
			"attrs": { "level": 2 },
			"content": [{
				"type": "text",
				"text": "2. Objetivo"
			}]
		},
		{
			"type": "var_richtext",
			"attrs": { "ref": "objetivo_evento" }
		},
		{
			"type": "heading",
			"attrs": { "level": 2 },
			"content": [{
				"type": "text",
				"text": "3. Metodologia"
			}]
		},
		{
			"type": "var_richtext",
			"attrs": { "ref": "metodologia" }
		},
		{
			"type": "heading",
			"attrs": { "level": 2 },
			"content": [{
				"type": "text",
				"text": "4. Lista de Participantes"
			}]
		},
		{
			"type": "var_table",
			"attrs": {
				"ref": "lista_participantes",
				"columns": "[\"nome\",\"cpf\",\"faixa_etaria\",\"presenca\"]",
				"caption": "Participantes da atividade"
			}
		},
		{
			"type": "heading",
			"attrs": { "level": 2 },
			"content": [{
				"type": "text",
				"text": "5. Equipe de Execução"
			}]
		},
		{
			"type": "var_table",
			"attrs": {
				"ref": "equipe_execucao",
				"columns": "[\"nome\",\"cargo\",\"carga_horaria\"]",
				"caption": "Equipe responsável pela execução"
			}
		},
		{
			"type": "heading",
			"attrs": { "level": 2 },
			"content": [{
				"type": "text",
				"text": "6. Conclusão"
			}]
		},
		{
			"type": "var_richtext",
			"attrs": { "ref": "conclusao" }
		},
		{
			"type": "paragraph",
			"content": [
				{
					"type": "text",
					"text": "Coordenador: ",
					"marks": [{ "type": "strong" }]
				},
				{
					"type": "var_text",
					"attrs": { "ref": "nome_coordenador" }
				},
				{
					"type": "text",
					"text": " — "
				},
				{
					"type": "var_text",
					"attrs": { "ref": "cargo_coordenador" }
				}
			]
		}
	]
};
function buildShell() {
	document.getElementById("app").innerHTML = `
    <header class="app-header">
      <div class="app-logo">
        <div class="logo-icon">📄</div>
        <span>GeRelat<span class="logo-dot">Editor</span></span>
      </div>

      <nav class="app-nav">
        <button class="nav-tab active" data-page="editor">✏️ Template</button>
        <button class="nav-tab" data-page="variables">⟨⟩ Variáveis</button>
        <button class="nav-tab" data-page="reports">📄 Relatórios</button>
      </nav>

      <div class="header-spacer"></div>

      <div class="header-actions" id="editor-header-actions">
        <button id="btn-undo" class="btn btn-ghost btn-sm" title="Desfazer (Ctrl+Z)">↩︎</button>
        <button id="btn-redo" class="btn btn-ghost btn-sm" title="Refazer (Ctrl+Y)">↪︎</button>
        <button id="btn-export-download" class="btn btn-primary btn-sm">⬇ Exportar JSON</button>
      </div>
    </header>

    <!-- Editor page -->
    <div id="page-editor" class="page-wrapper">
      <div class="toolbar" id="toolbar">
        <div class="toolbar-group">
          <span class="toolbar-label">Formato</span>
          <button id="fmt-bold"      class="btn btn-fmt btn-ghost" title="Negrito (Ctrl+B)"><b>B</b></button>
          <button id="fmt-italic"    class="btn btn-fmt btn-ghost" title="Itálico (Ctrl+I)"><i>I</i></button>
          <button id="fmt-underline" class="btn btn-fmt btn-ghost" title="Sublinhado (Ctrl+U)"><u>U</u></button>
          <button id="fmt-code"      class="btn btn-fmt btn-ghost" title="Código">&lt;/&gt;</button>
        </div>
        <div class="toolbar-separator"></div>
        <div class="toolbar-group">
          <span class="toolbar-label">Bloco</span>
          <button id="fmt-h1"   class="btn btn-fmt btn-ghost">H1</button>
          <button id="fmt-h2"   class="btn btn-fmt btn-ghost">H2</button>
          <button id="fmt-h3"   class="btn btn-fmt btn-ghost">H3</button>
          <button id="fmt-para" class="btn btn-fmt btn-ghost" title="Parágrafo">¶</button>
          <button id="fmt-bq"   class="btn btn-fmt btn-ghost" title="Citação">"</button>
        </div>
        <div class="toolbar-separator"></div>
        <div class="toolbar-group">
          <span class="toolbar-label">Nodos</span>
          <button id="btn-var-text"     class="btn btn-node btn-node-text"     title="Variável texto (Ctrl+Shift+T)">⟨T⟩</button>
          <button id="btn-var-richtext" class="btn btn-node btn-node-richtext" title="Variável richtext (Ctrl+Shift+W)">⟨W⟩</button>
          <button id="btn-var-image"    class="btn btn-node btn-node-image"    title="Variável imagem (Ctrl+Shift+I)">⟨🖼⟩</button>
          <button id="btn-var-table"    class="btn btn-node btn-node-table"    title="Variável tabela (Ctrl+Shift+A)">⟨📊⟩</button>
          <button id="btn-custom-text"  class="btn btn-node btn-node-custom"   title="Bloco livre (Ctrl+Shift+E)">📝</button>
        </div>
      </div>

      <div class="editor-layout">
        <div class="editor-pane">
          <div class="editor-paper">
            <div id="editor-mount"></div>
          </div>
        </div>

        <div class="side-panel">
          <div class="panel-tabs">
            <div class="panel-tab active" id="tab-refs"    data-tab="refs">🔖 Refs</div>
            <div class="panel-tab"        id="tab-json"    data-tab="json">{ } JSON</div>
            <div class="panel-tab"        id="tab-import"  data-tab="import">⬆ Import</div>
            <div class="panel-tab"        id="tab-config"  data-tab="config">⚙️ Config</div>
          </div>

          <div class="panel-content">
            <!-- Refs tab -->
            <div class="panel-section active" id="section-refs">
              <div class="section-title">Referências no documento</div>
              <div class="var-list" id="var-list"></div>
            </div>

            <!-- JSON tab -->
            <div class="panel-section" id="section-json">
              <div class="section-title">JSON do documento</div>
              <div class="json-actions">
                <button id="btn-refresh-json" class="btn btn-ghost btn-sm">↻ Atualizar</button>
                <button id="btn-copy-json"    class="btn btn-ghost btn-sm">📋 Copiar</button>
              </div>
              <div class="json-output" id="json-output"></div>
            </div>

            <!-- Import tab -->
            <div class="panel-section" id="section-import">
              <div class="section-title">Importar JSON</div>
              <div class="import-area">
                <p style="font-size:13px; color:var(--text-secondary); margin-bottom:4px">
                  Cole o JSON de um documento ProseMirror para reconstruí-lo no editor.
                </p>
                <textarea
                  id="import-textarea"
                  class="import-textarea"
                  placeholder='{ "type": "doc", "content": [...] }'
                ></textarea>
                <button id="btn-import-json" class="btn btn-primary">⬆ Carregar</button>
              </div>
            </div>

            <!-- Config tab -->
            <div class="panel-section" id="section-config">
              <div class="section-title">Configuração da API</div>
              <div style="padding: 8px 0">
                <div class="auth-status" id="auth-status"></div>

                <div class="form-group">
                  <label>URL da API</label>
                  <input id="cfg-base" type="text" class="form-input" value="${getBase()}" placeholder="http://localhost:8000" />
                </div>

                <div class="form-group">
                  <label>Projeto ID</label>
                  <input id="cfg-projeto" type="number" class="form-input" value="${getProjetoId()}" min="1" placeholder="1" />
                </div>

                <div class="section-title" style="margin:14px 0 10px">Login</div>
                <div class="form-group">
                  <label>E-mail</label>
                  <input id="cfg-email" type="email" class="form-input" placeholder="admin@gerelat.dev" />
                </div>
                <div class="form-group">
                  <label>Senha</label>
                  <input id="cfg-password" type="password" class="form-input" placeholder="Senha" />
                </div>
                <div style="display:flex;gap:6px;margin-bottom:16px">
                  <button id="btn-login" class="btn btn-primary btn-sm" style="flex:1">Entrar</button>
                  <button id="btn-logout" class="btn btn-ghost btn-sm" style="flex:1">Sair</button>
                </div>

                <button id="btn-save-config" class="btn btn-primary btn-sm" style="width:100%;margin-bottom:16px">Salvar Configuração</button>

                <hr style="border:none;border-top:1px solid var(--border);margin-bottom:14px" />

                <div class="section-title" style="margin-bottom:10px">Salvar Template</div>
                <div class="form-group">
                  <label>Nome do Template</label>
                  <input id="cfg-tpl-name" type="text" class="form-input" placeholder="Ex: Relatório Mensal" />
                </div>
                <div style="display:flex;gap:6px;margin-bottom:6px">
                  <button id="btn-save-tpl" class="btn btn-primary btn-sm" style="flex:1">💾 Salvar JSON como Template</button>
                </div>
                <div class="form-group" style="margin-top:8px">
                  <label>Atualizar Template Existente (ID)</label>
                  <div style="display:flex;gap:6px">
                    <input id="cfg-tpl-id" type="number" class="form-input" min="1" placeholder="ID" style="width:80px;flex-shrink:0" />
                    <button id="btn-update-tpl" class="btn btn-ghost btn-sm" style="flex:1">↻ Atualizar</button>
                  </div>
                </div>

                <hr style="border:none;border-top:1px solid var(--border);margin:14px 0" />

                <div class="section-title" style="margin-bottom:10px">Importar DOCX</div>
                <p style="font-size:11px;color:var(--text-muted);margin-bottom:8px;line-height:1.5">
                  Converte um arquivo .docx em JSON ProseMirror e carrega no editor.
                </p>
                <input id="cfg-docx-input" type="file" accept=".docx" style="display:none" />
                <button id="btn-pick-docx" class="btn btn-ghost btn-sm" style="width:100%">📂 Carregar DOCX no Editor</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Variables page -->
    <div id="page-variables" class="page-wrapper" style="display:none; overflow-y:auto"></div>

    <!-- Reports page -->
    <div id="page-reports" class="page-wrapper" style="display:none; overflow-y:auto"></div>
  `;
}
buildShell();
var currentPage = "editor";
function navigateTo(page) {
	currentPage = page;
	[
		"editor",
		"variables",
		"reports"
	].forEach((p) => {
		document.getElementById(`page-${p}`).style.display = p === page ? "" : "none";
	});
	document.querySelectorAll(".nav-tab").forEach((t) => {
		t.classList.toggle("active", t.dataset.page === page);
	});
	const editorActions = document.getElementById("editor-header-actions");
	if (editorActions) editorActions.style.display = page === "editor" ? "" : "none";
	if (page === "variables") variablesPage.init(document.getElementById("page-variables"));
	if (page === "reports") reportsPage.init(document.getElementById("page-reports"));
}
document.querySelectorAll(".nav-tab").forEach((tab) => {
	tab.addEventListener("click", () => navigateTo(tab.dataset.page));
});
var modePlugin = new Plugin({ filterTransaction(tr, state) {
	if (!tr.docChanged) return true;
	let allowed = true;
	tr.steps.forEach((step) => {
		if (!allowed) return;
		if (typeof step.from !== "number") return;
		let startInside = false;
		let endInside = false;
		try {
			let $from = state.doc.resolve(step.from);
			for (let i = $from.depth; i > 0; i--) if ($from.node(i).type.name === "custom_text") startInside = true;
			let $to = state.doc.resolve(step.to ?? step.from);
			for (let i = $to.depth; i > 0; i--) if ($to.node(i).type.name === "custom_text") endInside = true;
		} catch {}
		if (startInside || endInside) allowed = false;
	});
	return allowed;
} });
var editorState = EditorState.create({
	doc: schema.nodeFromJSON(INITIAL_DOC),
	plugins: [
		modePlugin,
		history(),
		buildInputRules(),
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
	]
});
var view = new EditorView(document.getElementById("editor-mount"), {
	state: editorState,
	nodeViews,
	dispatchTransaction(tr) {
		const newState = view.state.apply(tr);
		view.updateState(newState);
		refreshPanel(newState);
	}
});
window._editorView = view;
function activateTab(tabId) {
	document.querySelectorAll(".panel-tab").forEach((t) => t.classList.remove("active"));
	document.querySelectorAll(".panel-section").forEach((s) => s.classList.remove("active"));
	document.getElementById(`tab-${tabId}`)?.classList.add("active");
	document.getElementById(`section-${tabId}`)?.classList.add("active");
}
function refreshPanel(editorState) {
	const refs = collectRefs(editorState.doc);
	renderVarList(document.getElementById("var-list"), refs);
	if (document.getElementById("section-json")?.classList.contains("active")) updateJsonOutput(editorState);
}
function updateJsonOutput(editorState) {
	const json = getDocJson(editorState);
	const output = document.getElementById("json-output");
	if (output) output.innerHTML = highlightJson(json);
}
refreshPanel(editorState);
function updateAuthStatus() {
	const el = document.getElementById("auth-status");
	if (!el) return;
	el.innerHTML = Boolean(getAccessToken() || getRefreshToken()) ? "<div class=\"auth-pill auth-pill-ok\">Autenticado</div><small>Sessão ativa para criar templates e gerar relatórios.</small>" : "<div class=\"auth-pill auth-pill-warn\">Não autenticado</div><small>Faça login com e-mail e senha para liberar as ações na API.</small>";
}
async function performLogin() {
	const base = document.getElementById("cfg-base").value.trim();
	const email = document.getElementById("cfg-email").value.trim();
	const password = document.getElementById("cfg-password").value;
	const projetoId = parseInt(document.getElementById("cfg-projeto").value, 10);
	if (!base) {
		showToast("URL da API obrigatória.", "error");
		return;
	}
	if (!email) {
		showToast("E-mail obrigatório.", "error");
		return;
	}
	if (!password) {
		showToast("Senha obrigatória.", "error");
		return;
	}
	if (!projetoId || projetoId < 1) {
		showToast("ID de projeto inválido.", "error");
		return;
	}
	const btn = document.getElementById("btn-login");
	btn.disabled = true;
	btn.textContent = "Entrando...";
	try {
		saveConfig(base, projetoId);
		await api.loginWithCredentials(email, password);
		updateAuthStatus();
		showToast("Login efetuado com sucesso.");
	} catch (err) {
		showToast(`Erro no login: ${err.message}`, "error");
	} finally {
		btn.disabled = false;
		btn.textContent = "Entrar";
	}
}
async function performLogout() {
	await api.logout();
	updateAuthStatus();
	showToast("Sessão encerrada.");
}
document.getElementById("fmt-bold").addEventListener("click", () => {
	toggleBold(view.state, view.dispatch);
	view.focus();
});
document.getElementById("fmt-italic").addEventListener("click", () => {
	toggleItalic(view.state, view.dispatch);
	view.focus();
});
document.getElementById("fmt-underline").addEventListener("click", () => {
	toggleUnderline(view.state, view.dispatch);
	view.focus();
});
document.getElementById("fmt-code").addEventListener("click", () => {
	toggleCode(view.state, view.dispatch);
	view.focus();
});
document.getElementById("fmt-h1").addEventListener("click", () => {
	setHeading(1)(view.state, view.dispatch);
	view.focus();
});
document.getElementById("fmt-h2").addEventListener("click", () => {
	setHeading(2)(view.state, view.dispatch);
	view.focus();
});
document.getElementById("fmt-h3").addEventListener("click", () => {
	setHeading(3)(view.state, view.dispatch);
	view.focus();
});
document.getElementById("fmt-para").addEventListener("click", () => {
	setParagraph(view.state, view.dispatch);
	view.focus();
});
document.getElementById("fmt-bq").addEventListener("click", () => {
	wrapBlockquote(view.state, view.dispatch);
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
async function openVarText() {
	const result = await modalVarText();
	if (!result) return;
	const ref = result.ref.trim();
	if (!ref) {
		showToast("Informe a referência.", "error");
		return;
	}
	insertVarText(ref)(view.state, view.dispatch);
	view.focus();
	showToast(`var_text [${ref}] inserida`);
}
async function openVarRichtext() {
	const result = await modalVarRichtext();
	if (!result) return;
	const ref = result.ref.trim();
	if (!ref) {
		showToast("Informe a referência.", "error");
		return;
	}
	insertVarRichtext(ref)(view.state, view.dispatch);
	view.focus();
	showToast(`var_richtext [${ref}] inserida`);
}
async function openVarImage() {
	const result = await modalVarImage();
	if (!result) return;
	const ref = result.ref.trim();
	if (!ref) {
		showToast("Informe a referência.", "error");
		return;
	}
	insertVarImage(ref, result.caption)(view.state, view.dispatch);
	view.focus();
	showToast(`var_image [${ref}] inserida`);
}
async function openVarTable() {
	const result = await modalVarTable();
	if (!result) return;
	const ref = result.ref.trim();
	if (!ref) {
		showToast("Informe a referência.", "error");
		return;
	}
	insertVarTable(ref, result.columns ? result.columns.split(",").map((c) => c.trim()).filter(Boolean) : [], result.caption)(view.state, view.dispatch);
	view.focus();
	showToast(`var_table [${ref}] inserida`);
}
async function openCustomText() {
	const result = await modalCustomText();
	if (!result) return;
	const label = result.label.trim() || "bloco";
	insertCustomText(label)(view.state, view.dispatch);
	view.focus();
	showToast(`Bloco "${label}" inserido`);
}
document.getElementById("btn-var-text").addEventListener("click", openVarText);
document.getElementById("btn-var-richtext").addEventListener("click", openVarRichtext);
document.getElementById("btn-var-image").addEventListener("click", openVarImage);
document.getElementById("btn-var-table").addEventListener("click", openVarTable);
document.getElementById("btn-custom-text").addEventListener("click", openCustomText);
document.addEventListener("keydown", (e) => {
	if (!e.ctrlKey || !e.shiftKey) return;
	if (currentPage !== "editor") return;
	const key = e.key.toUpperCase();
	if (key === "T") {
		e.preventDefault();
		openVarText();
	} else if (key === "W") {
		e.preventDefault();
		openVarRichtext();
	} else if (key === "I") {
		e.preventDefault();
		openVarImage();
	} else if (key === "A") {
		e.preventDefault();
		openVarTable();
	} else if (key === "E") {
		e.preventDefault();
		openCustomText();
	}
});
document.querySelectorAll(".panel-tab").forEach((tab) => {
	tab.addEventListener("click", () => {
		const tabId = tab.dataset.tab;
		activateTab(tabId);
		if (tabId === "json") updateJsonOutput(view.state);
	});
});
document.getElementById("btn-refresh-json").addEventListener("click", () => {
	updateJsonOutput(view.state);
	showToast("JSON atualizado");
});
document.getElementById("btn-copy-json").addEventListener("click", async () => {
	try {
		await navigator.clipboard.writeText(getDocJson(view.state));
		showToast("JSON copiado");
	} catch {
		showToast("Erro ao copiar", "error");
	}
});
document.getElementById("btn-export-download").addEventListener("click", () => {
	const json = getDocJson(view.state);
	const blob = new Blob([json], { type: "application/json" });
	const url = URL.createObjectURL(blob);
	const a = document.createElement("a");
	a.href = url;
	a.download = "template-document.json";
	a.click();
	URL.revokeObjectURL(url);
	showToast("JSON exportado");
});
document.getElementById("btn-import-json").addEventListener("click", () => {
	const textarea = document.getElementById("import-textarea");
	const raw = textarea.value.trim();
	if (!raw) {
		showToast("Cole um JSON antes de importar", "error");
		return;
	}
	try {
		const doc = schema.nodeFromJSON(JSON.parse(raw));
		const newState = EditorState.create({
			doc,
			plugins: view.state.plugins
		});
		view.updateState(newState);
		refreshPanel(newState);
		textarea.value = "";
		activateTab("refs");
		showToast("Documento importado");
	} catch (err) {
		showToast(`Erro ao importar: ${err.message}`, "error", 4e3);
	}
});
document.getElementById("btn-save-config").addEventListener("click", () => {
	const base = document.getElementById("cfg-base").value.trim();
	const projetoId = parseInt(document.getElementById("cfg-projeto").value, 10);
	if (!base) {
		showToast("URL da API obrigatória.", "error");
		return;
	}
	if (!projetoId || projetoId < 1) {
		showToast("ID de projeto inválido.", "error");
		return;
	}
	saveConfig(base, projetoId);
	updateAuthStatus();
	showToast("Configuração salva.");
});
document.getElementById("btn-login").addEventListener("click", performLogin);
document.getElementById("btn-logout").addEventListener("click", performLogout);
updateAuthStatus();
document.getElementById("btn-save-tpl").addEventListener("click", async () => {
	const name = document.getElementById("cfg-tpl-name").value.trim();
	const projetoId = getProjetoId();
	if (!name) {
		showToast("Informe o nome do template.", "error");
		return;
	}
	const btn = document.getElementById("btn-save-tpl");
	btn.disabled = true;
	try {
		const modelo_json = view.state.doc.toJSON();
		const result = await api.createTemplateFromJson({
			nome: name,
			projeto: projetoId,
			modelo_json
		});
		showToast(`Template enviado para processamento. Task: ${result.task_id}`);
		try {
			const taskResult = (await api.pollTask(result.task_id)).result;
			if (taskResult && taskResult.type === "Template" && taskResult.id) {
				document.getElementById("cfg-tpl-id").value = taskResult.id;
				showToast(`Template #${taskResult.id} criado!`, "success");
			} else showToast("Template criado, mas não foi possível obter o ID automaticamente.", "info");
		} catch (err) {
			showToast(`Erro ao processar task: ${err.message}`, "error");
		}
	} catch (err) {
		showToast(`Erro: ${err.message}`, "error");
	} finally {
		btn.disabled = false;
	}
});
document.getElementById("btn-update-tpl").addEventListener("click", async () => {
	const id = parseInt(document.getElementById("cfg-tpl-id").value, 10);
	if (!id || id < 1) {
		showToast("Informe o ID do template.", "error");
		return;
	}
	const btn = document.getElementById("btn-update-tpl");
	btn.disabled = true;
	try {
		const modelo_json = view.state.doc.toJSON();
		await api.updateTemplateJson(id, modelo_json);
		showToast(`Template #${id} atualizado.`);
	} catch (err) {
		showToast(`Erro: ${err.message}`, "error");
	} finally {
		btn.disabled = false;
	}
});
document.getElementById("btn-pick-docx").addEventListener("click", () => {
	document.getElementById("cfg-docx-input").click();
});
document.getElementById("cfg-docx-input").addEventListener("change", async (e) => {
	const file = e.target.files?.[0];
	if (!file) return;
	e.target.value = "";
	const btn = document.getElementById("btn-pick-docx");
	btn.disabled = true;
	btn.textContent = "⏳ Convertendo...";
	try {
		const result = await api.convertDocx(file);
		const doc = schema.nodeFromJSON(result.modelo_json);
		const newState = EditorState.create({
			doc,
			plugins: view.state.plugins
		});
		view.updateState(newState);
		refreshPanel(newState);
		activateTab("refs");
		showToast("DOCX convertido e carregado no editor.");
	} catch (err) {
		showToast(`Erro na conversão: ${err.message}`, "error", 5e3);
	} finally {
		btn.disabled = false;
		btn.textContent = "📂 Carregar DOCX no Editor";
	}
});
//#endregion
