import { BrowserWindow } from 'electron';
import { autoUpdater } from 'electron-updater';
import { Theme } from './main';
import { getAssetPath } from './util';

const LOADING_IMAGES = {
  neuro: [
    'https://storage.neurokaraoke.com/image/loading/loading_neuro_1.webp',
    'https://storage.neurokaraoke.com/image/loading/loading_neuro_2.webp',
    'https://storage.neurokaraoke.com/image/loading/loading_neuro_3.webp',
    'https://storage.neurokaraoke.com/image/loading/loading_neuro_4.webp',
    'https://storage.neurokaraoke.com/image/loading/loading_neuro_5.webp',
  ],
  evil: [
    'https://storage.neurokaraoke.com/image/loading/loading_evil_1.webp',
    'https://storage.neurokaraoke.com/image/loading/loading_evil_2.webp',
    'https://storage.neurokaraoke.com/image/loading/loading_evil_3.webp',
    'https://storage.neurokaraoke.com/image/loading/loading_evil_4.webp',
    'https://storage.neurokaraoke.com/image/loading/loading_evil_5.webp',
  ],
  smocus: [
    'https://storage.neurokaraoke.com/image/loading/twins_loading_1.webp',
    'https://storage.neurokaraoke.com/image/loading/twins_loading_2.webp',
    'https://storage.neurokaraoke.com/image/loading/twins_loading_3.webp',
  ],
};

// Minimum time the splash stays visible (ms)
const MIN_SPLASH_MS = 2000;

/**
 * Show the splash window, check for updates, and resolve when the app should proceed.
 * Resolves `true` if the app should continue launching (no update or error).
 * If an update is downloaded, it calls quitAndInstall — the app restarts automatically.
 *
 * @param {string} theme - 'neuro' | 'evil' | 'smocus'
 * @param {string} iconPath - path to the app icon
 * @returns {Promise<boolean>} true if app should continue to main window
 */
export function runSplashUpdater(theme: Theme, iconPath: string): Promise<boolean> {
  if (!process.env.DISABLE_AUTOUPDATE) return new Promise((resolve) => {
    const splashWindow = new BrowserWindow({
      width: 400,
      height: 300,
      frame: false,
      resizable: false,
      transparent: true,
      alwaysOnTop: true,
      center: true,
      skipTaskbar: true,
      icon: iconPath,
      webPreferences: {
        nodeIntegration: true,
        contextIsolation: false,
      },
    });

    splashWindow.loadFile(getAssetPath('splash.html'));

    const splashOpenedAt = Date.now();

    // Pick a random loading image for the theme
    const images = LOADING_IMAGES[theme] || LOADING_IMAGES.neuro;
    const randomImage = images[Math.floor(Math.random() * images.length)];

    splashWindow.webContents.once('did-finish-load', () => {
      splashWindow.webContents.send('splash-loading-url', randomImage);
    });

    function setStatus(text: string) {
      if (!splashWindow.isDestroyed()) {
        splashWindow.webContents.send('splash-status', text);
      }
    }

    function setProgress(percent: number) {
      if (!splashWindow.isDestroyed()) {
        splashWindow.webContents.send('splash-progress', percent);
      }
    }

    let didResolve = false;

    function closeSplashAndContinue() {
      if (didResolve) return;
      didResolve = true;
      const elapsed = Date.now() - splashOpenedAt;
      const remaining = Math.max(0, MIN_SPLASH_MS - elapsed);
      setTimeout(() => {
        if (!splashWindow.isDestroyed()) splashWindow.close();
        resolve(true);
      }, remaining);
    }

    // Configure electron-updater
    autoUpdater.autoDownload = true;
    autoUpdater.autoInstallOnAppQuit = true;
    autoUpdater.logger = console;

    autoUpdater.on('checking-for-update', () => {
      setStatus('Checking for updates...');
    });

    autoUpdater.on('update-available', () => {
      setStatus('Downloading update...');
      setProgress(0);
    });

    autoUpdater.on('download-progress', (progress) => {
      const percent = Math.round(progress.percent);
      setStatus(`Downloading update... ${percent}%`);
      setProgress(percent);
    });

    autoUpdater.on('update-downloaded', () => {
      setStatus('Installing update...');
      setProgress(100);
      // Brief delay so the user sees "Installing..." before restart
      setTimeout(() => {
        autoUpdater.quitAndInstall(false, true);
      }, 1500);
    });

    autoUpdater.on('update-not-available', () => {
      setStatus('Launching...');
      setProgress(-1);
      closeSplashAndContinue();
    });

    autoUpdater.on('error', (err) => {
      console.error('Auto-updater error:', err.message);
      setStatus('Launching...');
      setProgress(-1);
      closeSplashAndContinue();
    });

    // Start update check
    autoUpdater.checkForUpdates().then((result) => {
      // In dev mode, electron-updater skips and returns null without emitting events
      if (!result) {
        setStatus('Launching...');
        setProgress(-1);
        closeSplashAndContinue();
      }
    }).catch((err) => {
      console.error('Failed to check for updates:', err.message);
      setStatus('Launching...');
      setProgress(-1);
      closeSplashAndContinue();
    });
  });

  return Promise.resolve(true);
}