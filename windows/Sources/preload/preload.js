const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('clipboardAPI', {
    getHistory: () => ipcRenderer.invoke('get-clipboard-history'),
    getCurrentClipboard: () => ipcRenderer.invoke('get-current-clipboard'),
    copyItem: (content) => ipcRenderer.invoke('copy-item', content),
    deleteItem: (id) => ipcRenderer.invoke('delete-item', id),
    copyAll: () => ipcRenderer.invoke('copy-all'),
    dedupe: () => ipcRenderer.invoke('dedupe'),
    clearAll: () => ipcRenderer.invoke('clear-all'),
    getFavorites: () => ipcRenderer.invoke('get-favorites'),
    getFavoriteTopics: () => ipcRenderer.invoke('get-favorite-topics'),
    setFavorite: (index, content, topic) => ipcRenderer.invoke('set-favorite', index, content, topic),
    addFavorite: (content) => ipcRenderer.invoke('add-favorite', content),
    copyFavorite: (index) => ipcRenderer.invoke('copy-favorite', index),
    getWindowState: () => ipcRenderer.invoke('get-window-state'),
    setWindowExpanded: (expanded) => ipcRenderer.invoke('set-window-expanded', expanded),
    getAutoLaunch: () => ipcRenderer.invoke('get-auto-launch'),
    setAutoLaunch: (enabled) => ipcRenderer.invoke('set-auto-launch', enabled),
    hideWindow: () => ipcRenderer.invoke('hide-window'),
    onWindowModeChanged: (callback) => {
        ipcRenderer.on('window-mode-changed', (event, data) => callback(data));
    },
    onClipboardUpdate: (callback) => {
        ipcRenderer.on('clipboard-updated', (event, data) => callback(data));
    }
});
