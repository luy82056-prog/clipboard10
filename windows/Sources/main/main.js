const { app, BrowserWindow, Tray, Menu, globalShortcut, clipboard, nativeImage, ipcMain, screen } = require('electron');
const path = require('path');
const fs = require('fs');

const WINDOW_SIZES = {
    collapsed: { width: 272, height: 68 },
    expanded: { width: 372, height: 610 }
};
const WINDOW_MARGIN = 18;

let mainWindow = null;
let tray = null;
let clipboardHistory = [];
let favorites = Array(10).fill('');
let favoriteTopics = Object.create(null);
let lastContent = '';
let pollInterval = null;
let isExpanded = false;

const appIconPath = path.join(__dirname, '..', '..', 'Assets', 'app-icon.png');
if (process.env.CLIPBOARD10_DATA_DIR) {
    app.setPath('userData', path.resolve(process.env.CLIPBOARD10_DATA_DIR));
}
const gotSingleInstanceLock = app.requestSingleInstanceLock();

if (!gotSingleInstanceLock) app.quit();

function getStorePath() {
    return path.join(app.getPath('userData'), 'favorites.json');
}

function loadFavorites() {
    try {
        const entries = JSON.parse(fs.readFileSync(path.join(app.getPath('userData'), 'favorite-topics.json'), 'utf8'));
        if (Array.isArray(entries)) for (const entry of entries) {
            if (typeof entry.content === 'string' && typeof entry.topic === 'string') favoriteTopics[entry.content] = entry.topic;
        }
    } catch (e) { /* Existing versions have no topic file. */ }
    try {
        const raw = fs.readFileSync(getStorePath(), 'utf8');
        const parsed = JSON.parse(raw);
        if (Array.isArray(parsed)) {
            favorites = Array.from({ length: 10 }, (_, index) => String(parsed[index] || ''));
        }
    } catch (e) {
        favorites = Array(10).fill('');
    }
}

function saveFavorites() {
    fs.mkdirSync(app.getPath('userData'), { recursive: true });
    fs.writeFileSync(getStorePath(), JSON.stringify(favorites, null, 2), 'utf8');
    const entries = favorites.filter(Boolean).map(content => ({ content, topic: favoriteTopics[content] || '' }));
    fs.writeFileSync(path.join(app.getPath('userData'), 'favorite-topics.json'), JSON.stringify(entries, null, 2), 'utf8');
}

function getDockedPosition(size, display = screen.getPrimaryDisplay()) {
    const area = display.workArea;
    return {
        x: area.x + area.width - size.width - WINDOW_MARGIN,
        y: area.y + WINDOW_MARGIN
    };
}

function createWindow() {
    const initialSize = WINDOW_SIZES.collapsed;
    const initialPosition = getDockedPosition(initialSize);

    mainWindow = new BrowserWindow({
        ...initialSize,
        ...initialPosition,
        show: false,
        frame: false,
        transparent: true,
        backgroundColor: '#00000000',
        resizable: false,
        maximizable: false,
        minimizable: false,
        fullscreenable: false,
        skipTaskbar: true,
        alwaysOnTop: true,
        hasShadow: true,
        icon: appIconPath,
        webPreferences: {
            preload: path.join(__dirname, '..', 'preload', 'preload.js'),
            contextIsolation: true,
            nodeIntegration: false
        }
    });

    mainWindow.setAlwaysOnTop(true, 'floating', 1);
    mainWindow.setVisibleOnAllWorkspaces(true, { visibleOnFullScreen: true });
    mainWindow.loadFile(path.join(__dirname, '..', 'renderer', 'index.html'));
    mainWindow.on('closed', () => { mainWindow = null; });
}

function createTray() {
    let trayIcon;

    try {
        trayIcon = nativeImage.createFromPath(appIconPath);
        if (trayIcon.isEmpty()) trayIcon = nativeImage.createEmpty();
    } catch (e) {
        trayIcon = nativeImage.createEmpty();
    }

    tray = new Tray(trayIcon.resize({ width: 16, height: 16 }));
    tray.setToolTip('Clipboard 10 · 文字暂存器');
    tray.setContextMenu(Menu.buildFromTemplate([
        { label: '展开 Clipboard 10', click: () => setWindowMode(true) },
        { label: '收起为浮窗', click: () => setWindowMode(false) },
        { type: 'separator' },
        { label: '退出', click: () => app.quit() }
    ]));
    tray.on('click', () => setWindowMode(!isExpanded));
}

function calculateResizedBounds(targetSize) {
    if (!mainWindow || mainWindow.isDestroyed()) {
        return { ...targetSize, ...getDockedPosition(targetSize) };
    }

    const current = mainWindow.getBounds();
    const display = screen.getDisplayNearestPoint({
        x: current.x + Math.round(current.width / 2),
        y: current.y + Math.round(current.height / 2)
    });

    return { ...targetSize, ...getDockedPosition(targetSize, display) };
}

function setWindowMode(expanded, { focus = true } = {}) {
    if (!mainWindow || mainWindow.isDestroyed()) createWindow();

    isExpanded = Boolean(expanded);
    const targetSize = isExpanded ? WINDOW_SIZES.expanded : WINDOW_SIZES.collapsed;
    mainWindow.setAlwaysOnTop(true, 'floating', 1);
    mainWindow.setBounds(calculateResizedBounds(targetSize), true);
    mainWindow.webContents.send('window-mode-changed', { expanded: isExpanded });

    if (!mainWindow.isVisible()) mainWindow.showInactive();
    if (focus && isExpanded) mainWindow.focus();
}

function showFloatingWindow(expanded = true) {
    if (!mainWindow || mainWindow.isDestroyed()) createWindow();
    setWindowMode(expanded);
}

function startClipboardMonitoring() {
    lastContent = clipboard.readText();

    pollInterval = setInterval(() => {
        const currentContent = clipboard.readText();

        if (currentContent && currentContent !== lastContent) {
            lastContent = currentContent;
            const existingIndex = clipboardHistory.findIndex(item => item.content === currentContent);
            if (existingIndex !== -1) clipboardHistory.splice(existingIndex, 1);

            clipboardHistory.unshift({
                id: Date.now(),
                content: currentContent,
                timestamp: new Date().toISOString()
            });

            if (clipboardHistory.length > 10) clipboardHistory = clipboardHistory.slice(0, 10);
            if (mainWindow && !mainWindow.isDestroyed()) {
                mainWindow.webContents.send('clipboard-updated', clipboardHistory);
            }
        }
    }, 500);
}

function registerGlobalShortcut() {
    globalShortcut.register('CommandOrControl+Shift+V', () => showFloatingWindow(true));
}

app.whenReady().then(() => {
    if (!gotSingleInstanceLock) return;

    loadFavorites();
    createWindow();
    createTray();
    startClipboardMonitoring();
    registerGlobalShortcut();

    mainWindow.webContents.once('did-finish-load', () => {
        setWindowMode(false, { focus: false });
        mainWindow.showInactive();
    });

    app.on('activate', () => showFloatingWindow(true));
});

app.on('second-instance', () => showFloatingWindow(true));
app.on('will-quit', () => {
    globalShortcut.unregisterAll();
    if (pollInterval) clearInterval(pollInterval);
});
app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') app.quit();
});

ipcMain.handle('get-clipboard-history', () => clipboardHistory);
ipcMain.handle('get-current-clipboard', () => clipboard.readText());
ipcMain.handle('copy-item', (event, content) => {
    clipboard.writeText(content);
    lastContent = content;
    return true;
});
ipcMain.handle('delete-item', (event, id) => {
    clipboardHistory = clipboardHistory.filter(item => item.id !== id);
    return clipboardHistory;
});
ipcMain.handle('copy-all', () => {
    const allText = clipboardHistory.map(item => item.content).join('\n\n');
    clipboard.writeText(allText);
    lastContent = allText;
    return true;
});
ipcMain.handle('dedupe', () => {
    const seen = new Set();
    clipboardHistory = clipboardHistory.filter(item => {
        if (seen.has(item.content)) return false;
        seen.add(item.content);
        return true;
    });
    return clipboardHistory;
});
ipcMain.handle('clear-all', () => {
    clipboardHistory = [];
    return clipboardHistory;
});
ipcMain.handle('get-favorites', () => favorites);
ipcMain.handle('get-favorite-topics', () => ({ ...favoriteTopics }));
ipcMain.handle('set-favorite', (event, index, content, topic) => {
    if (!Number.isInteger(index) || index < 0 || index >= 10) return favorites;
    const previous = favorites[index];
    favorites[index] = String(content || '').trim();
    if (favorites[index]) favoriteTopics[favorites[index]] = typeof topic === 'string' ? topic.trim().slice(0, 60) : (favoriteTopics[previous] || '');
    if (previous !== favorites[index] && !favorites.includes(previous)) delete favoriteTopics[previous];
    saveFavorites();
    return favorites;
});
ipcMain.handle('add-favorite', (event, content) => {
    const value = String(content || '').trim();
    if (!value) return favorites;

    const existingIndex = favorites.findIndex(item => item === value);
    if (existingIndex !== -1) {
        favorites.splice(existingIndex, 1);
        favorites.unshift(value);
    } else {
        const emptyIndex = favorites.findIndex(item => !item);
        if (emptyIndex !== -1) favorites[emptyIndex] = value;
        else favorites = [value, ...favorites.slice(0, 9)];
    }

    favorites = Array.from({ length: 10 }, (_, index) => favorites[index] || '');
    saveFavorites();
    return favorites;
});
ipcMain.handle('copy-favorite', (event, index) => {
    const content = favorites[index] || '';
    if (!content) return false;
    clipboard.writeText(content);
    lastContent = content;
    return true;
});
ipcMain.handle('get-window-state', () => ({ expanded: isExpanded }));
ipcMain.handle('set-window-expanded', (event, expanded) => {
    setWindowMode(Boolean(expanded));
    return { expanded: isExpanded };
});
ipcMain.handle('get-auto-launch', () => app.getLoginItemSettings().openAtLogin);
ipcMain.handle('set-auto-launch', (event, enabled) => {
    app.setLoginItemSettings({
        openAtLogin: Boolean(enabled),
        path: app.getPath('exe'),
        args: []
    });
    return app.getLoginItemSettings().openAtLogin;
});
ipcMain.handle('hide-window', () => {
    setWindowMode(false, { focus: false });
});
