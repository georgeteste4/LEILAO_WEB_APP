import { Platform } from 'react-native';
import * as FileSystem from 'expo-file-system';
import * as IntentLauncher from 'expo-intent-launcher';
import * as Linking from 'expo-linking';
import { AppReleaseInfo } from '../types';

export const CURRENT_VERSION = 'v1.0.0';
const GITHUB_REPO = 'georgeteste4/LEILAO_WEB_APP';
const GITHUB_RELEASES_API = `https://api.github.com/repos/${GITHUB_REPO}/releases/latest`;

export async function checkAppUpdate(): Promise<AppReleaseInfo> {
  try {
    const response = await fetch(GITHUB_RELEASES_API, {
      headers: { 'Accept': 'application/vnd.github.v3+json' }
    });

    if (!response.ok) {
      throw new Error(`Falha ao verificar atualizações no GitHub: HTTP ${response.status}`);
    }

    const release = await response.json();
    const latestVersion = release.tag_name || release.name || 'v1.0.0';

    let apkUrl: string | undefined;
    let apkSize: number | undefined;

    if (Array.isArray(release.assets)) {
      const apkAsset = release.assets.find((a: any) => a.name && a.name.endsWith('.apk'));
      if (apkAsset) {
        apkUrl = apkAsset.browser_download_url;
        apkSize = apkAsset.size;
      }
    }

    const hasUpdate = compareVersions(latestVersion, CURRENT_VERSION) > 0;

    return {
      version: latestVersion,
      name: release.name || latestVersion,
      published_at: release.published_at,
      body: release.body || 'Melhorias de desempenho e correções de estabilidade.',
      html_url: release.html_url,
      apk_url: apkUrl,
      apk_size: apkSize,
      has_update: hasUpdate
    };
  } catch (error: any) {
    console.error('Erro ao checar atualização:', error);
    throw error;
  }
}

export async function downloadAndInstallApk(
  apkUrl: string,
  onProgress?: (percent: number) => void
) {
  if (Platform.OS === 'web') {
    window.open(apkUrl, '_blank');
    return;
  }

  try {
    const filename = 'leilao_app_update.apk';
    const localUri = `${FileSystem.cacheDirectory}${filename}`;

    const downloadResumable = FileSystem.createDownloadResumable(
      apkUrl,
      localUri,
      {},
      (downloadProgress) => {
        const progress = downloadProgress.totalBytesWritten / downloadProgress.totalBytesExpectedToWrite;
        if (onProgress) {
          onProgress(Math.round(progress * 100));
        }
      }
    );

    const result = await downloadResumable.downloadAsync();
    if (!result || !result.uri) {
      throw new Error('Falha no download do APK.');
    }

    const contentUri = await FileSystem.getContentUriAsync(result.uri);

    if (Platform.OS === 'android') {
      await IntentLauncher.startActivityAsync('android.intent.action.VIEW', {
        data: contentUri,
        flags: 1,
        type: 'application/vnd.android.package-archive'
      });
    } else {
      Linking.openURL(result.uri);
    }
  } catch (error: any) {
    console.error('Erro ao instalar APK:', error);
    throw error;
  }
}

function compareVersions(v1: string, v2: string): number {
  const clean1 = v1.replace(/^v/, '').split('.').map(Number);
  const clean2 = v2.replace(/^v/, '').split('.').map(Number);

  for (let i = 0; i < Math.max(clean1.length, clean2.length); i++) {
    const num1 = clean1[i] || 0;
    const num2 = clean2[i] || 0;
    if (num1 > num2) return 1;
    if (num1 < num2) return -1;
  }
  return 0;
}
