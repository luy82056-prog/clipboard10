let history = [];
let favorites = Array(10).fill('');
let activeTab = 'recent';
let toastTimer = null;
let favoriteTopics = {};
let editingIndex = null;

const elements = {
    shell: document.getElementById('appShell'),
    list: document.getElementById('list'),
    recentTab: document.getElementById('recentTab'),
    favoritesTab: document.getElementById('favoritesTab'),
    recentActions: document.getElementById('recentActions'),
    favoritesActions: document.getElementById('favoritesActions'),
    recordCount: document.getElementById('recordCount'),
    collapsedPreview: document.getElementById('collapsedPreview'),
    autoLaunch: document.getElementById('autoLaunchToggle'),
    toast: document.getElementById('toast')
};

async function loadData() {
    const [loadedHistory, loadedFavorites, windowState, autoLaunch] = await Promise.all([
        window.clipboardAPI.getHistory(),
        window.clipboardAPI.getFavorites(),
        window.clipboardAPI.getWindowState(),
        window.clipboardAPI.getAutoLaunch()
    ]);

    history = loadedHistory;
    favorites = loadedFavorites;
    favoriteTopics = await window.clipboardAPI.getFavoriteTopics();
    elements.autoLaunch.checked = Boolean(autoLaunch);
    applyWindowMode(Boolean(windowState.expanded));
    render();
}

function applyWindowMode(expanded) {
    elements.shell.classList.toggle('expanded', expanded);
    elements.shell.classList.toggle('collapsed', !expanded);
}

async function setExpanded(expanded) {
    applyWindowMode(expanded);
    await window.clipboardAPI.setWindowExpanded(expanded);
}

async function copyItem(index) {
    const item = history[index];
    if (!item) return;
    await window.clipboardAPI.copyItem(item.content);
    showToast('已复制到剪贴板');
}

async function deleteItem(id) {
    history = await window.clipboardAPI.deleteItem(id);
    render();
}

async function copyAll() {
    if (history.length === 0) return;
    await window.clipboardAPI.copyAll();
    showToast('十段文字已合并复制');
}

async function dedupe() {
    const before = history.length;
    history = await window.clipboardAPI.dedupe();
    render();
    showToast(before === history.length ? '记录已经很整洁' : '重复内容已整理');
}

async function clearAll() {
    if (history.length === 0) return;
    if (confirm('确定清空全部剪贴板历史吗？')) {
        history = await window.clipboardAPI.clearAll();
        render();
        showToast('历史记录已清空');
    }
}

async function pinItem(index) {
    const item = history[index];
    if (!item) return;
    favorites = await window.clipboardAPI.addFavorite(item.content);
    activeTab = 'favorites';
    render();
    showToast('已收入常用');
}

async function copyFavorite(index) {
    const ok = await window.clipboardAPI.copyFavorite(index);
    if (ok) showToast('常用文字已复制');
}

async function editFavorite(index) {
    editingIndex = index;
    const current = favorites[index] || '';
    document.getElementById('favoriteTopic').value = favoriteTopics[current] || '';
    document.getElementById('favoriteBody').value = current;
    document.getElementById('favoriteEditor').showModal();
    document.getElementById('favoriteTopic').focus();
}

async function clearFavorite(index) {
    if (!favorites[index]) return;
    favorites = await window.clipboardAPI.setFavorite(index, '');
    render();
    showToast('已移出常用');
}

function switchTab(tab) {
    activeTab = tab;
    render();
}

function render() {
    const isRecent = activeTab === 'recent';
    elements.recentTab.classList.toggle('active', isRecent);
    elements.favoritesTab.classList.toggle('active', !isRecent);
    elements.recentActions.classList.toggle('hidden', !isRecent);
    elements.favoritesActions.classList.toggle('hidden', isRecent);

    if (isRecent) renderHistory();
    else renderFavorites();

    const count = isRecent ? history.length : favorites.filter(Boolean).length;
    elements.recordCount.textContent = String(count).padStart(2, '0') + ' / 10';
    document.getElementById('copyAllButton').disabled = history.length === 0;
    document.getElementById('dedupeButton').disabled = history.length < 2;
    document.getElementById('clearAllButton').disabled = history.length === 0;
    updateCollapsedPreview();
}

function renderHistory() {
    if (history.length === 0) {
        elements.list.innerHTML = emptyState('剪贴板还是空白', '复制一段文字，它会安静地留在这里。');
        return;
    }

    elements.list.innerHTML = history.map((item, index) =>
        '<article class="item">' +
            '<div class="item-index">' + String(index + 1).padStart(2, '0') + '</div>' +
            '<div class="item-content" title="' + escapeAttribute(item.content) + '"><span>' + escapeHtml(item.content) + '</span></div>' +
            '<div class="item-tools">' +
                '<button class="item-btn" type="button" data-action="copy" data-index="' + index + '" title="复制">取</button>' +
                '<button class="item-btn" type="button" data-action="pin" data-index="' + index + '" title="存入常用">藏</button>' +
                '<button class="item-btn delete" type="button" data-action="delete" data-id="' + item.id + '" title="删除">删</button>' +
            '</div>' +
        '</article>'
    ).join('');
}

function renderFavorites() {
    elements.list.innerHTML = favorites.map((content, index) =>
        '<article class="item ' + (content ? '' : 'empty-slot') + '">' +
            '<div class="item-index">' + String(index + 1).padStart(2, '0') + '</div>' +
            '<div class="item-content favorite-copy" title="' + (content ? escapeAttribute(content) : '') + '">' +
                '<button type="button" class="favorite-topic" data-action="edit-favorite" data-index="' + index + '" title="编辑主题与正文">' + escapeHtml(favoriteTopics[content] || (content ? '＋ 添加主题' : '＋ 新建常用')) + '</button><span>' +
                (content ? escapeHtml(content) : '空白，等待一句值得留下的话') +
            '</span></div>' +
            '<div class="item-tools">' +
                '<button class="item-btn" type="button" data-action="copy-favorite" data-index="' + index + '" title="复制" ' + (content ? '' : 'disabled') + '>取</button>' +
                '<button class="item-btn" type="button" data-action="edit-favorite" data-index="' + index + '" title="编辑">编</button>' +
                '<button class="item-btn delete" type="button" data-action="clear-favorite" data-index="' + index + '" title="清空" ' + (content ? '' : 'disabled') + '>空</button>' +
            '</div>' +
        '</article>'
    ).join('');
}

function emptyState(title, note) {
    return '<div class="empty"><div><div class="empty-mark">“</div>' +
        '<strong>' + title + '</strong><p>' + note + '</p></div></div>';
}

async function addCurrentClipboard() {
    const text = await window.clipboardAPI.getCurrentClipboard();
    if (!text.trim()) {
        showToast('当前剪贴板没有文字');
        return;
    }
    favorites = await window.clipboardAPI.addFavorite(text);
    activeTab = 'favorites';
    render();
    showToast('已收入常用');
}

function updateCollapsedPreview() {
    const latest = history[0] && history[0].content.trim();
    elements.collapsedPreview.textContent = latest ? latest.replace(/\s+/g, ' ') : '文字暂存器';
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = String(text);
    return div.innerHTML;
}

function escapeAttribute(text) {
    return escapeHtml(text).replace(/"/g, '&quot;');
}

function showToast(message) {
    clearTimeout(toastTimer);
    elements.toast.textContent = message;
    elements.toast.classList.add('show');
    toastTimer = setTimeout(() => elements.toast.classList.remove('show'), 1500);
}

document.getElementById('expandButton').addEventListener('click', () => setExpanded(true));
document.getElementById('collapseButton').addEventListener('click', () => setExpanded(false));
document.getElementById('copyAllButton').addEventListener('click', copyAll);
document.getElementById('dedupeButton').addEventListener('click', dedupe);
document.getElementById('clearAllButton').addEventListener('click', clearAll);
document.getElementById('addCurrentButton').addEventListener('click', addCurrentClipboard);

document.querySelectorAll('[data-tab]').forEach(button => {
    button.addEventListener('click', () => switchTab(button.dataset.tab));
});

elements.list.addEventListener('click', event => {
    const button = event.target.closest('[data-action]');
    if (!button || button.disabled) return;

    const index = Number(button.dataset.index);
    const actions = {
        copy: () => copyItem(index),
        pin: () => pinItem(index),
        delete: () => deleteItem(Number(button.dataset.id)),
        'copy-favorite': () => copyFavorite(index),
        'edit-favorite': () => editFavorite(index),
        'clear-favorite': () => clearFavorite(index)
    };
    if (actions[button.dataset.action]) actions[button.dataset.action]();
});

elements.autoLaunch.addEventListener('change', async () => {
    const requested = elements.autoLaunch.checked;
    elements.autoLaunch.disabled = true;
    try {
        elements.autoLaunch.checked = await window.clipboardAPI.setAutoLaunch(requested);
        showToast(elements.autoLaunch.checked ? '已设为随 Windows 启动' : '已关闭开机自启动');
    } catch (error) {
        elements.autoLaunch.checked = !requested;
        showToast('设置失败，请稍后重试');
    } finally {
        elements.autoLaunch.disabled = false;
    }
});

document.addEventListener('keydown', event => {
    if (event.key === 'Escape' && !document.getElementById('favoriteEditor').open) setExpanded(false);
});

document.getElementById('cancelFavorite').addEventListener('click', () => document.getElementById('favoriteEditor').close());
document.getElementById('favoriteForm').addEventListener('submit', async event => {
    event.preventDefault();
    const button = document.getElementById('saveFavorite');
    const body = document.getElementById('favoriteBody').value;
    const topic = document.getElementById('favoriteTopic').value;
    if (!body.trim()) { document.getElementById('editorError').textContent = '请填写要复制的正文。'; return; }
    button.disabled = true;
    try {
        favorites = await window.clipboardAPI.setFavorite(editingIndex, body, topic);
        favoriteTopics = await window.clipboardAPI.getFavoriteTopics();
        document.getElementById('favoriteEditor').close();
        render();
        showToast('主题与正文已保存');
    } catch (error) { document.getElementById('editorError').textContent = '保存失败，请重试。'; }
    finally { button.disabled = false; }
});
document.getElementById('favoriteEditor').addEventListener('close', () => { document.getElementById('editorError').textContent = ''; });

window.clipboardAPI.onWindowModeChanged(data => applyWindowMode(Boolean(data.expanded)));
window.clipboardAPI.onClipboardUpdate(data => {
    history = data;
    render();
});

loadData().catch(() => showToast('载入失败，请重新启动应用'));
