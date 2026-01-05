# Firebase Rules Deployment Script for Windows
# Lubok Antu RescueNet

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Firebase Security Rules Deployment" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Check if Firebase CLI is installed
Write-Host "Checking Firebase CLI..." -ForegroundColor Yellow
try {
    $firebaseVersion = firebase --version
    Write-Host "✓ Firebase CLI found: $firebaseVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Firebase CLI not found. Installing globally..." -ForegroundColor Red
    Write-Host "Run: npm install -g firebase-tools"
    Exit 1
}

Write-Host ""

# List current projects
Write-Host "📋 Available Firebase projects:" -ForegroundColor Yellow
firebase projects:list
Write-Host ""

Write-Host "⚠️  Current project should be: lubok-antu-rescuenet" -ForegroundColor Yellow
Write-Host "If not selected, run: firebase use lubok-antu-rescuenet" -ForegroundColor Yellow
Write-Host ""

# Prompt user to continue
$response = Read-Host "Continue with deployment? (y/n)"
if ($response -eq "y" -or $response -eq "Y") {
    Write-Host ""
    Write-Host "🚀 Deploying Firestore security rules..." -ForegroundColor Yellow
    
    firebase deploy --only firestore:rules
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Deployment successful!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📝 Next steps:" -ForegroundColor Cyan
        Write-Host "1. Run your Flutter app: flutter run" -ForegroundColor White
        Write-Host "2. In your app initialization, execute: await FirebaseSeeder.seedDatabase();" -ForegroundColor White
        Write-Host "3. Check console for seeding results" -ForegroundColor White
    } else {
        Write-Host ""
        Write-Host "❌ Deployment failed. Check the error messages above." -ForegroundColor Red
    }
} else {
    Write-Host "Deployment cancelled." -ForegroundColor Yellow
}
