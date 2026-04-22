<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FcmService
{
    public function sendToToken(?string $deviceToken, string $title, string $message, array $data = []): bool
    {
        if (!$deviceToken) {
            Log::info('Push notification dilewati karena device token kosong', [
                'title' => $title,
            ]);
            return false;
        }

        $projectId = env('FIREBASE_PROJECT_ID');
        $serviceAccountPath = env('FIREBASE_SERVICE_ACCOUNT_PATH');

        if (!$projectId || !$serviceAccountPath) {
            Log::warning('Konfigurasi Firebase HTTP v1 belum lengkap', [
                'has_project_id' => !empty($projectId),
                'has_service_account_path' => !empty($serviceAccountPath),
            ]);
            return false;
        }

        if (!file_exists($serviceAccountPath)) {
            Log::warning('File service account Firebase tidak ditemukan', [
                'path' => $serviceAccountPath,
            ]);
            return false;
        }

        $serviceAccount = json_decode(file_get_contents($serviceAccountPath), true);

        if (!is_array($serviceAccount)) {
            Log::warning('Isi service account Firebase tidak valid');
            return false;
        }

        $accessToken = $this->getAccessToken($serviceAccount);

        if (!$accessToken) {
            return false;
        }

        try {
            $response = Http::withToken($accessToken)
                ->withHeaders([
                    'Content-Type' => 'application/json; charset=UTF-8',
                ])
                ->post("https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send", [
                    'message' => [
                        'token' => $deviceToken,
                        'notification' => [
                            'title' => $title,
                            'body' => $message,
                        ],
                        'data' => $this->normalizeData($data, $title, $message),
                        'android' => [
                            'priority' => 'high',
                            'notification' => [
                                'channel_id' => 'koperasi_notifications',
                            ],
                        ],
                    ],
                ]);

            if ($response->failed()) {
                Log::warning('Gagal mengirim push notification ke FCM HTTP v1', [
                    'status' => $response->status(),
                    'body' => $response->body(),
                    'title' => $title,
                ]);

                return false;
            }

            Log::info('Push notification berhasil dikirim ke FCM HTTP v1', [
                'title' => $title,
                'response' => $response->json(),
            ]);

            return true;
        } catch (\Throwable $error) {
            Log::error('Terjadi error saat mengirim push notification', [
                'message' => $error->getMessage(),
            ]);

            return false;
        }
    }

    public function sendToMany(iterable $users, string $title, string $message, array $data = []): void
    {
        foreach ($users as $user) {
            $this->sendToToken($user->device_token, $title, $message, $data);
        }
    }

    private function getAccessToken(array $serviceAccount): ?string
    {
        if (
            empty($serviceAccount['client_email']) ||
            empty($serviceAccount['private_key']) ||
            empty($serviceAccount['token_uri'])
        ) {
            Log::warning('Field penting service account Firebase tidak lengkap');
            return null;
        }

        $now = time();
        $header = $this->base64UrlEncode(json_encode([
            'alg' => 'RS256',
            'typ' => 'JWT',
        ]));

        $payload = $this->base64UrlEncode(json_encode([
            'iss' => $serviceAccount['client_email'],
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
            'aud' => $serviceAccount['token_uri'],
            'iat' => $now,
            'exp' => $now + 3600,
        ]));

        $signatureInput = $header . '.' . $payload;
        $privateKey = openssl_pkey_get_private($serviceAccount['private_key']);

        if (!$privateKey) {
            Log::warning('Private key service account Firebase tidak bisa dibaca');
            return null;
        }

        $signature = '';
        $signed = openssl_sign($signatureInput, $signature, $privateKey, 'sha256WithRSAEncryption');
        openssl_free_key($privateKey);

        if (!$signed) {
            Log::warning('Gagal membuat JWT untuk Firebase');
            return null;
        }

        $jwt = $signatureInput . '.' . $this->base64UrlEncode($signature);

        try {
            $response = Http::asForm()->post($serviceAccount['token_uri'], [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $jwt,
            ]);

            if ($response->failed()) {
                Log::warning('Gagal mengambil access token Firebase', [
                    'status' => $response->status(),
                    'body' => $response->body(),
                ]);

                return null;
            }

            return $response->json('access_token');
        } catch (\Throwable $error) {
            Log::error('Terjadi error saat mengambil access token Firebase', [
                'message' => $error->getMessage(),
            ]);

            return null;
        }
    }

    private function base64UrlEncode(string $value): string
    {
        return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    }

    private function normalizeData(array $data, string $title, string $message): array
    {
        $normalizedData = [];

        foreach ($data as $key => $value) {
            $normalizedData[(string) $key] = is_scalar($value)
                ? (string) $value
                : json_encode($value);
        }

        $normalizedData['title'] = $title;
        $normalizedData['body'] = $message;

        return $normalizedData;
    }
}
