# LifePrep — 戰時生存準備指南

<p align="center">
  <img src="https://img.shields.io/badge/平台-iOS%2017%2B%20%7C%20iPadOS%2017%2B-blue" />
  <img src="https://img.shields.io/badge/語言-Swift%205.9-orange" />
  <img src="https://img.shields.io/badge/框架-SwiftUI%20%7C%20SwiftData-green" />
  <img src="https://img.shields.io/badge/後端-Firebase-yellow" />
</p>

## 簡介

**LifePrep** 是一款專為戰時或重大災難情境設計的 iOS/iPadOS 生存準備應用程式。無論是在家中還是外出，App 都能提供完整的生存指南，並在有無網路的情況下皆可正常使用。

---

## 主要功能

### 📚 生存指南
- 內建 10 大分類、20 餘項詳細指南，包含：
  - **糧食儲存**：儲備原則、長期保存食物清單、無電力烹飪方式
  - **飲水準備**：飲水儲存計畫、過濾與淨化方法、野外水源尋找
  - **醫療準備**：急救包清單、戰傷急救處置、慢性病患者注意事項
  - **財務配置**：現金策略、黃金白銀等實物資產、保險與文件準備
  - **居家防護**：安全庇護室設置、停電應對措施
  - **通訊計畫**：家庭緊急聯絡計畫、無線電通訊
  - **緊急撤離**：72 小時緊急背包清單、疏散路線規劃
  - **野外求生**：臨時庇護所搭建、野外生火技術
  - **城市安全**：遭受攻擊時的應對、人際與社群安全
  - **心理準備**：壓力管理與心理韌性

### 🔄 離線優先設計
- App 內建完整種子資料，**無需網路即可使用**
- 有網路時自動從 GitHub 拉取最新內容，增量更新並儲存至本地端
- 所有資料使用 **SwiftData** 儲存於裝置本機

### 💬 線上通訊（需要網路）
- 使用 **Firebase Auth** 帳號登入
- 透過 **Firebase Firestore** 進行即時文字聊天
- 支援**一對一**及**群組**對話
- 語音通話架構（信令層已完成，音訊串流可整合 WebRTC/Agora）

### 📡 離線藍牙通訊（無需網路）
- 使用 **MultipeerConnectivity** 框架
- 在無網路環境下透過**藍牙或 WiFi Direct** 與附近裝置通訊
- 支援傳送**文字訊息**與**圖片**
- 支援**藍牙語音通話**（透過 AVAudioEngine 串流音訊）
- 通訊紀錄自動儲存於本地端，可離線查閱

---

## 技術架構

| 層級 | 技術 |
|------|------|
| UI 框架 | SwiftUI |
| 本地資料庫 | SwiftData |
| 認證 | Firebase Authentication |
| 線上聊天 | Firebase Firestore |
| 圖片儲存 | Firebase Storage |
| 藍牙/P2P 通訊 | MultipeerConnectivity |
| 語音串流 | AVAudioEngine |
| 網路偵測 | NWPathMonitor |
| 內容更新 | GitHub Raw JSON |
| 專案管理 | XcodeGen |

---

## 環境需求

- **Xcode 16+**
- **iOS / iPadOS 17.0+**
- Firebase 專案（需設定 `GoogleService-Info.plist`）

---

## 安裝與設定

### 1. Clone 專案
```bash
git clone https://github.com/TimTonKa/LifePrep.git
cd LifePrep
```

### 2. 安裝 XcodeGen（如尚未安裝）
```bash
brew install xcodegen
```

### 3. 產生 Xcode 專案
```bash
xcodegen generate
```

### 4. 設定 Firebase
1. 前往 [Firebase Console](https://console.firebase.google.com) 建立專案
2. 新增 iOS 應用程式，Bundle ID：`com.timtonka.LifePrep`
3. 下載 `GoogleService-Info.plist` 並放入 `LifePrep/` 目錄
4. 啟用以下服務：
   - **Authentication**（電子郵件/密碼）
   - **Firestore Database**
   - **Storage**（選用，用於線上圖片傳送）

### 5. 開啟並執行
```bash
open LifePrep.xcodeproj
```
在 Xcode 中選擇目標裝置，按 **⌘R** 執行。

---

## 內容更新機制

生存指南的內容來源為 `content/survival_guide.json`。  
App 啟動後若有網路，將自動從以下 URL 拉取更新：

```
https://raw.githubusercontent.com/TimTonKa/LifePrep/main/content/survival_guide.json
```

若要更新指南內容，直接修改此 JSON 檔案並推送至 GitHub 即可，使用者下次開啟 App 時會自動更新。

---

## 注意事項

- `GoogleService-Info.plist` 已加入 `.gitignore`，請勿將真實憑證提交至公開 repo
- Firestore 安全規則建議在正式上線前改為驗證規則，避免資料被任意存取
- 語音通話（網路版）需額外整合 WebRTC 函式庫（如 GoogleWebRTC 或 Agora SDK）

---

---

# LifePrep — War Survival Preparation Guide

## Overview

**LifePrep** is an iOS/iPadOS application designed for war-time and major disaster scenarios. It provides comprehensive survival guides and communication tools that work both online and completely offline.

---

## Key Features

### 📚 Survival Guide
- 10 categories with 20+ detailed guides covering:
  - **Food Storage**: Stockpiling principles, long-term preservation, cooking without power
  - **Water Preparedness**: Storage plans, filtration & purification, finding water in the wild
  - **Medical Preparedness**: First aid kit checklist, trauma care, chronic illness management
  - **Financial Planning**: Cash strategy, gold/silver assets, document backups
  - **Home Defense**: Safe room setup, blackout & power outage procedures
  - **Communication Plan**: Family emergency plan, radio communication
  - **Emergency Evacuation**: 72-hour bug-out bag checklist, evacuation route planning
  - **Wilderness Survival**: Building shelters, fire-starting techniques
  - **Urban Safety**: Responding to attacks, community safety
  - **Mental Preparedness**: Stress management, psychological resilience

### 🔄 Offline-First Design
- Full seed data bundled in the app — **works without internet**
- Automatically fetches the latest content from GitHub when online, merging updates locally
- All data persisted on-device using **SwiftData**

### 💬 Online Communication (requires internet)
- **Firebase Auth** account login
- Real-time text chat via **Firebase Firestore**
- Supports **direct** and **group** conversations
- Voice call architecture (signaling layer complete; audio stream ready for WebRTC/Agora integration)

### 📡 Offline Bluetooth Communication (no internet required)
- Built on Apple's **MultipeerConnectivity** framework
- Communicates with nearby devices via **Bluetooth or WiFi Direct**
- Supports sending **text messages** and **images**
- Supports **Bluetooth voice calls** via AVAudioEngine audio streaming
- Chat history automatically saved locally for offline access

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI Framework | SwiftUI |
| Local Database | SwiftData |
| Authentication | Firebase Authentication |
| Online Chat | Firebase Firestore |
| Image Storage | Firebase Storage |
| Bluetooth / P2P | MultipeerConnectivity |
| Voice Streaming | AVAudioEngine |
| Network Detection | NWPathMonitor |
| Content Updates | GitHub Raw JSON |
| Project Generation | XcodeGen |

---

## Requirements

- **Xcode 16+**
- **iOS / iPadOS 17.0+**
- Firebase project (requires `GoogleService-Info.plist`)

---

## Setup

### 1. Clone the repository
```bash
git clone https://github.com/TimTonKa/LifePrep.git
cd LifePrep
```

### 2. Install XcodeGen (if not already installed)
```bash
brew install xcodegen
```

### 3. Generate the Xcode project
```bash
xcodegen generate
```

### 4. Configure Firebase
1. Go to [Firebase Console](https://console.firebase.google.com) and create a project
2. Add an iOS app with Bundle ID: `com.timtonka.LifePrep`
3. Download `GoogleService-Info.plist` and place it in the `LifePrep/` directory
4. Enable the following services:
   - **Authentication** (Email/Password)
   - **Firestore Database**
   - **Storage** (optional, for online image sharing)

### 5. Open and run
```bash
open LifePrep.xcodeproj
```
Select a target device in Xcode and press **⌘R** to run.

---

## Content Update Mechanism

The survival guide content is sourced from `content/survival_guide.json`.  
When online, the app automatically fetches updates from:

```
https://raw.githubusercontent.com/TimTonKa/LifePrep/main/content/survival_guide.json
```

To push content updates, simply edit this JSON file and push to GitHub. Users will receive the update automatically the next time they open the app with an internet connection.

---

## Security Notes

- `GoogleService-Info.plist` is listed in `.gitignore` — never commit real credentials to a public repository
- Update Firestore security rules before production release to restrict access to authenticated users only
- Internet-based voice calls require an additional WebRTC library (e.g., GoogleWebRTC or Agora SDK)

---

## License

MIT License © 2026 TimTonKa
