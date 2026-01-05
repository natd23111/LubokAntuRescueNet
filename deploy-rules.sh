#!/bin/bash
# Firebase Rules Deployment Script for Lubok Antu RescueNet

echo "======================================"
echo "Firebase Security Rules Deployment"
echo "======================================"
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Installing globally..."
    npm install -g firebase-tools
fi

echo "✓ Firebase CLI is available"
echo ""

# List current projects
echo "📋 Available Firebase projects:"
firebase projects:list
echo ""

echo "⚠️  Make sure your project 'lubok-antu-rescuenet' is selected."
echo "If not selected, run: firebase use lubok-antu-rescuenet"
echo ""

# Prompt user to continue
read -p "Continue with deployment? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🚀 Deploying Firestore security rules..."
    firebase deploy --only firestore:rules
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Deployment successful!"
        echo ""
        echo "📝 Next steps:"
        echo "1. Run your Flutter app"
        echo "2. Execute: await FirebaseSeeder.seedDatabase();"
        echo "3. Check console for seeding results"
    else
        echo ""
        echo "❌ Deployment failed. Check the error messages above."
    fi
else
    echo "Deployment cancelled."
fi
