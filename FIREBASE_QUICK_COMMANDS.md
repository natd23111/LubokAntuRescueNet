# Quick Firebase Deployment - Terminal Commands

## 1. Ensure Firebase CLI is Installed
```bash
npm install -g firebase-tools
```

## 2. Login to Firebase
```bash
firebase login
```

## 3. Verify Your Project (Windows PowerShell)
```powershell
firebase projects:list
firebase use lubok-antu-rescuenet
```

Or on Bash/Linux/Mac:
```bash
firebase projects:list
firebase use lubok-antu-rescuenet
```

## 4. Deploy Security Rules
```bash
firebase deploy --only firestore:rules
```

## 5. Check Deployment Status
```bash
firebase status
```

## Windows PowerShell Quick Deploy Script

Save this as a function in your PowerShell profile for easy access:

```powershell
function Deploy-FirebaseRules {
    $projectPath = "E:\Unimas\Year 4\SELab\Project\Lubok Antu RescueNet"
    Set-Location $projectPath
    
    Write-Host "🚀 Deploying Firestore rules..." -ForegroundColor Yellow
    firebase deploy --only firestore:rules
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Rules deployed successfully!" -ForegroundColor Green
    } else {
        Write-Host "❌ Deployment failed!" -ForegroundColor Red
    }
}
```

Usage: `Deploy-FirebaseRules`

## Complete One-Line Command (PowerShell)
```powershell
firebase use lubok-antu-rescuenet; firebase deploy --only firestore:rules
```

## Checking Rules in Firebase Console

1. Go to: https://console.firebase.google.com
2. Select: lubok-antu-rescuenet
3. Click: Firestore Database → Rules
4. Verify the rules include seeding support

## Verify Seeding Success

Look for these collections in Firestore:
```
Collections:
├── aid_programs (7 documents)
├── aid_requests (5 documents)
├── emergency_reports (8 documents)
├── warnings (5 documents)
├── users (5 documents)
│   └── notifications (5 documents per user)
└── _metadata
```

## Rollback (if needed)

If deployment fails or you need to revert:

```bash
# Temporarily set test mode (not recommended for production)
firebase rules:test --service-account=path/to/serviceAccountKey.json

# Or manually edit and redeploy
firebase deploy --only firestore:rules
```

## Environment Setup (One Time)

```bash
# Set your default project
firebase use --add

# Select project: lubok-antu-rescuenet
# (Follow prompts)
```

---

**Quick Command Reference**
| Command | Purpose |
|---------|---------|
| `firebase login` | Authenticate with Firebase |
| `firebase projects:list` | List your Firebase projects |
| `firebase use lubok-antu-rescuenet` | Set active project |
| `firebase deploy --only firestore:rules` | Deploy security rules |
| `firebase status` | Check deployment status |
| `firebase rules:test` | Test rules locally |
