#!/bin/bash
# Script to build Flutter web app for production
echo "Building Flutter Web App for Production..."
flutter build web --release --web-renderer canvaskit

echo "Build complete. The output is in build/web/"
echo "You can host this on Vercel, Netlify, Firebase Hosting, or GitHub Pages."
