#!/bin/bash
set -e

# ============================================================
# سكريبت بناء Dynamic Island بدون Xcode IDE
# يحتاج فقط: Command Line Tools (خفيف ~1-2GB بدل Xcode الكامل ~15-40GB)
#
# تثبيت Command Line Tools (لو مش مثبتة عندك):
#   xcode-select --install
#
# طريقة الاستخدام:
#   1. افتح Terminal
#   2. cd لمكان فك ضغط المشروع (المجلد اللي فيه هذا الملف)
#   3. chmod +x build.sh
#   4. ./build.sh
# ============================================================

APP_NAME="DynamicIsland"
SRC_DIR="DynamicIsland"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "🔍 التحقق من وجود swiftc..."
if ! command -v swiftc &> /dev/null; then
    echo "❌ swiftc غير موجود. ثبّت Command Line Tools أولًا:"
    echo "   xcode-select --install"
    exit 1
fi
echo "✅ swiftc موجود: $(swiftc --version | head -n1)"

echo "🧹 تنظيف بناء سابق..."
rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

echo "🛠️  جمع ملفات Swift..."
SWIFT_FILES=$(find "$SRC_DIR" -name "*.swift")

echo "🔨 الترجمة (Compiling)..."
swiftc $SWIFT_FILES \
    -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
    -framework Cocoa \
    -framework SwiftUI \
    -framework Combine \
    -framework IOKit \
    -framework CoreAudio \
    -framework AudioToolbox \
    -framework Network \
    -framework CoreWLAN \
    -framework ServiceManagement \
    -framework UserNotifications \
    -target x86_64-apple-macosx11.0 \
    -O

echo "📦 نسخ Info.plist..."
cp "$SRC_DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

echo "✍️  التوقيع محليًا (ad-hoc، كافٍ للتشغيل على جهازك)..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo ""
echo "✅ تم البناء بنجاح!"
echo "📍 التطبيق موجود في: $APP_BUNDLE"
echo ""
echo "لتشغيله الآن:"
echo "   open \"$APP_BUNDLE\""
echo ""
echo "لنقله لمجلد Applications:"
echo "   cp -r \"$APP_BUNDLE\" /Applications/"
