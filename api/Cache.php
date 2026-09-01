<?php
declare(strict_types=1);

/**
 * Classe de cache simples baseada em arquivos JSON.
 * Armazena respostas em disco para evitar requisições repetidas ao site.
 */
class Cache
{
    private string $cacheDir;
    private int $defaultTtl;

    public function __construct(string $cacheDir = CACHE_DIR, int $defaultTtl = CACHE_TTL)
    {
        $this->cacheDir = $cacheDir;
        $this->defaultTtl = $defaultTtl;

        if (!is_dir($this->cacheDir)) {
            mkdir($this->cacheDir, 0755, true);
        }
    }

    /**
     * Gera o caminho do arquivo de cache a partir da chave.
     */
    private function getFilePath(string $key): string
    {
        $safeKey = md5($key);
        return $this->cacheDir . DIRECTORY_SEPARATOR . $safeKey . '.json';
    }

    /**
     * Obtém dados do cache se existirem e não estiverem expirados.
     * Retorna null se o cache não existir ou estiver expirado.
     */
    public function get(string $key): mixed
    {
        $filePath = $this->getFilePath($key);

        if (!file_exists($filePath)) {
            return null;
        }

        $content = file_get_contents($filePath);
        if ($content === false) {
            return null;
        }

        $cached = json_decode($content, true);
        if (!$cached || !isset($cached['expires_at'], $cached['data'])) {
            return null;
        }

        // Verificar se o cache expirou
        if (time() > $cached['expires_at']) {
            unlink($filePath);
            return null;
        }

        return $cached['data'];
    }

    /**
     * Armazena dados no cache com TTL.
     */
    public function set(string $key, mixed $data, ?int $ttl = null): void
    {
        $ttl = $ttl ?? $this->defaultTtl;
        $filePath = $this->getFilePath($key);

        $cached = [
            'created_at' => date('Y-m-d H:i:s'),
            'expires_at' => time() + $ttl,
            'key' => $key,
            'data' => $data,
        ];

        file_put_contents($filePath, json_encode($cached, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
    }

    /**
     * Limpa todo o cache.
     */
    public function clear(): int
    {
        $count = 0;
        $files = glob($this->cacheDir . DIRECTORY_SEPARATOR . '*.json');

        if ($files) {
            foreach ($files as $file) {
                if (unlink($file)) {
                    $count++;
                }
            }
        }

        return $count;
    }
}
