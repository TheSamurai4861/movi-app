# check-app-version

Fonction Edge Supabase utilisée par l'application Flutter pour décider si l'entrée dans l'app est autorisée.

## Contrat d'entrée

```json
{
  "appId": "movi",
  "environment": "prod",
  "appVersion": "1.0.2",
  "buildNumber": "9",
  "platform": "android",
  "osVersion": "Android 14"
}
```

## Contrat de sortie

```json
{
  "status": "force_update",
  "reasonCode": "min_supported_version_not_met",
  "currentVersion": "1.0.2",
  "minSupportedVersion": "1.1.0",
  "latestVersion": "1.2.0",
  "platform": "android",
  "updateUrl": "https://play.google.com/store/apps/details?id=...",
  "message": "Une mise à jour est requise pour continuer.",
  "cacheTtlSeconds": 21600
}
```

## Déploiement

```bash
supabase db push
supabase functions deploy check-app-version
```


cd C:\Users\berny\DEV\Flutter\movi
supabase login
supabase link --project-ref ibtgtmiohzlujuxmggfd
supabase db push
supabase functions deploy check-app-version
