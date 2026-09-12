import Foundation

public struct LocalizedStrings {
    public static func title(lang: AppLanguage) -> String {
        switch lang {
        case .ko: return "화이트아웃"
        default:  return "WhiteOut"
        }
    }

    public static func statusActive(lang: AppLanguage, percent: Int) -> String {
        switch lang {
        case .ko:     return "흰색 최대값 \(percent)%"
        case .ja:     return "最大白レベル: \(percent)%"
        case .zhHans: return "最大白电平: \(percent)%"
        case .zhHant: return "最大白電平: \(percent)%"
        case .de:     return "Max. Weiß: \(percent)%"
        case .en:     return "Max White: \(percent)%"
        }
    }

    public static func statusDisabled(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "비활성화됨"
        case .ja:     return "無効"
        case .zhHans: return "已停用"
        case .zhHant: return "已停用"
        case .de:     return "Deaktiviert"
        case .en:     return "Disabled"
        }
    }

    public static func reductionLabel(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "감소량"
        case .ja:     return "低減率"
        case .zhHans: return "降低程度"
        case .zhHant: return "降低程度"
        case .de:     return "Reduzierung"
        case .en:     return "Reduction"
        }
    }

    public static func preserveBlacks(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "검정 유지"
        case .ja:     return "黒レベル保持"
        case .zhHans: return "保留纯黑"
        case .zhHant: return "保留純黑"
        case .de:     return "Schwarz erhalten"
        case .en:     return "Preserve Blacks"
        }
    }

    public static func maxWhiteLevel(lang: AppLanguage, percent: Int) -> String {
        switch lang {
        case .ko:     return "흰색 최대값 \(percent)%"
        case .ja:     return "最大白レベル \(percent)%"
        case .zhHans: return "最大白电平 \(percent)%"
        case .zhHant: return "最大白電平 \(percent)%"
        case .de:     return "Max. Weißstufe \(percent)%"
        case .en:     return "Max white level \(percent)%"
        }
    }

    public static func shortcutToggle(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "단축키로 On/Off"
        case .ja:     return "ショートカットで切替"
        case .zhHans: return "快捷键开关"
        case .zhHant: return "快速鍵開關"
        case .de:     return "Per Kurzbefehl"
        case .en:     return "Toggle via Shortcut"
        }
    }

    public static func launchAtLogin(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "로그인 시 자동 실행"
        case .ja:     return "ログイン時に起動"
        case .zhHans: return "开机自动启动"
        case .zhHant: return "開機自動啟動"
        case .de:     return "Beim Login starten"
        case .en:     return "Launch at Login"
        }
    }

    public static func shortcutRecord(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "단축키 설정"
        case .ja:     return "ショートカット設定"
        case .zhHans: return "设置快捷键"
        case .zhHant: return "設定快速鍵"
        case .de:     return "Kurzbefehl aufnehmen"
        case .en:     return "Configure Shortcut"
        }
    }

    public static func curveTypeLabel(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "곡선 타입"
        case .ja:     return "カーブタイプ"
        case .zhHans: return "曲线类型"
        case .zhHant: return "曲線類型"
        case .de:     return "Kurventyp"
        case .en:     return "Curve Type"
        }
    }

    public static func curveGeneral(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "일반"
        case .ja:     return "標準"
        case .zhHans: return "标准"
        case .zhHant: return "標準"
        case .de:     return "Standard"
        case .en:     return "General"
        }
    }

    public static func curveDocs(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "문서·PDF"
        case .ja:     return "文書・PDF"
        case .zhHans: return "文档·PDF"
        case .zhHant: return "文件·PDF"
        case .de:     return "Dokumente · PDF"
        case .en:     return "Docs · PDF"
        }
    }

    public static func curveHighlights(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "하이라이트"
        case .ja:     return "ハイライト"
        case .zhHans: return "高光保护"
        case .zhHant: return "高光保護"
        case .de:     return "Glanzlichter"
        case .en:     return "Highlights"
        }
    }

    public static func manualCheckHelp(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "업데이트 확인 (120시간마다 자동 확인)"
        case .ja:     return "アップデートを確認 (120時間毎に自動確認)"
        case .zhHans: return "检查更新 (每120小时自动检查)"
        case .zhHant: return "檢查更新 (每120小時自動檢查)"
        case .de:     return "Nach Updates suchen (alle 120 Std.)"
        case .en:     return "Check for updates"
        }
    }

    public static func quitLabel(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "종료"
        case .ja:     return "終了"
        case .zhHans: return "退出"
        case .zhHant: return "結束"
        case .de:     return "Beenden"
        case .en:     return "Quit"
        }
    }

    public static func detailsTitle(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "밝기 변환 곡선 (x축 : 입력 밝기 → y축 : 출력 밝기)"
        case .ja:     return "輝度変換カーブ (x軸: 入力 → y軸: 出力)"
        case .zhHans: return "亮度转换曲线 (x轴: 输入 → y轴: 输出)"
        case .zhHant: return "亮度轉換曲線 (x軸: 輸入 → y軸: 輸出)"
        case .de:     return "Helligkeitskurve (x: Eingang ➔ y: Ausgang)"
        case .en:     return "Brightness Curve (x-axis: Input ➔ y-axis: Output)"
        }
    }

    public static func detailsSectionTitle(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "원리 및 비교 분석"
        case .ja:     return "動作原理と方式比較"
        case .zhHans: return "运作原理与对比"
        case .zhHant: return "運作原理與比較"
        case .de:     return "Prinzipien & Vergleich"
        case .en:     return "Principles & Comparison"
        }
    }

    public static func detailsHowItWorks(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "작동 방식 차이점"
        case .ja:     return "方式の違い"
        case .zhHans: return "方式差异对比"
        case .zhHant: return "方式差異比較"
        case .de:     return "Methodenvergleich"
        case .en:     return "Comparison of Methods"
        }
    }

    public static func updateDownloading(lang: AppLanguage, ver: String) -> String {
        switch lang {
        case .ko:     return "v\(ver) 다운로드 중..."
        case .ja:     return "v\(ver) をダウンロード中..."
        case .zhHans: return "正在下载 v\(ver)..."
        case .zhHant: return "正在下載 v\(ver)..."
        case .de:     return "Lade v\(ver) herunter..."
        case .en:     return "Downloading v\(ver)..."
        }
    }

    public static func updateAvailable(lang: AppLanguage, ver: String) -> String {
        switch lang {
        case .ko:     return "새 버전 v\(ver) 사용 가능"
        case .ja:     return "新バージョン v\(ver) が利用可能"
        case .zhHans: return "发现新版本 v\(ver)"
        case .zhHant: return "發現新版本 v\(ver)"
        case .de:     return "Neue Version v\(ver) verfügbar"
        case .en:     return "New version v\(ver) available"
        }
    }

    public static func updateClickToUpdate(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "클릭하여 자동 업데이트"
        case .ja:     return "クリックして自動更新"
        case .zhHans: return "点击自动更新"
        case .zhHant: return "點擊自動更新"
        case .de:     return "Klicken zum Aktualisieren"
        case .en:     return "Click to auto update"
        }
    }

    public static func updateNetworkErrorTitle(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "업데이트 오류"
        case .ja:     return "アップデートエラー"
        case .zhHans: return "更新错误"
        case .zhHant: return "更新錯誤"
        case .de:     return "Update-Fehler"
        case .en:     return "Update Error"
        }
    }

    public static func updateNetworkErrorMsg(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "업데이트 정보를 가져오지 못했습니다. 네트워크 연결 상태를 확인해 주세요."
        case .ja:     return "アップデート情報を取得できませんでした。ネットワーク接続を確認してください。"
        case .zhHans: return "无法获取更新信息，请检查网络连接。"
        case .zhHant: return "無法取得更新資訊，請檢查網路連線。"
        case .de:     return "Update-Informationen konnten nicht abgerufen werden. Bitte Netzwerkverbindung prüfen."
        case .en:     return "Failed to get update info. Please check your network connection."
        }
    }

    public static func allDisplays(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "모든 디스플레이"
        case .ja:     return "すべてのディスプレイ"
        case .zhHans: return "所有显示器"
        case .zhHant: return "所有顯示器"
        case .de:     return "Alle Displays"
        case .en:     return "All Displays"
        }
    }

    public static func displayLabel(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "디스플레이"
        case .ja:     return "ディスプレイ"
        case .zhHans: return "显示器"
        case .zhHant: return "顯示器"
        case .de:     return "Display"
        case .en:     return "Display"
        }
    }

    public static func appRulesSectionTitle(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "앱별 자동 설정"
        case .ja:     return "アプリ別ルール"
        case .zhHans: return "应用程序规则"
        case .zhHant: return "應用程式規則"
        case .de:     return "App-spezifische Regeln"
        case .en:     return "App-Specific Rules"
        }
    }

    public static func addRuleBtn(lang: AppLanguage, appName: String) -> String {
        switch lang {
        case .ko:     return "+ \(appName) 추가"
        case .ja:     return "+ \(appName) を追加"
        case .zhHans: return "+ 添加 \(appName)"
        case .zhHant: return "+ 新增 \(appName)"
        case .de:     return "+ \(appName) hinzufügen"
        case .en:     return "+ Add \(appName)"
        }
    }

    public static func addRuleBtnDefault(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "+ 앱 규칙 추가"
        case .ja:     return "+ アプリルールを追加"
        case .zhHans: return "+ 添加应用规则"
        case .zhHant: return "+ 新增應用規則"
        case .de:     return "+ App-Regel hinzufügen"
        case .en:     return "+ Add App Rule"
        }
    }

    public static func ruleActiveBanner(lang: AppLanguage, appName: String) -> String {
        switch lang {
        case .ko:     return "\(appName) 자동 적용 중"
        case .ja:     return "\(appName) ルール適用中"
        case .zhHans: return "\(appName) 规则生效中"
        case .zhHant: return "\(appName) 規則生效中"
        case .de:     return "\(appName)-Regel aktiv"
        case .en:     return "\(appName) rules active"
        }
    }

    public static func compareOurApp(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "Whiteout (GPU 감마 조절)"
        case .ja:     return "Whiteout (GPUガンマ)"
        case .zhHans: return "Whiteout (GPU硬件伽马)"
        case .zhHant: return "Whiteout (GPU硬體伽瑪)"
        case .de:     return "Whiteout (GPU-Gamma)"
        case .en:     return "Whiteout (GPU Gamma)"
        }
    }

    public static func compareOurAppDesc(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "검정색(0) 레벨을 100% 보존하여 명암비와 화질이 완벽히 유지됩니다."
        case .ja:     return "黒レベル(0)を100%維持し、コントラストと画質を損ないません。"
        case .zhHans: return "100%保留纯黑阶(0)，完美维持屏幕对比度与原生画质。"
        case .zhHant: return "100%保留純黑階(0)，完美維持螢幕對比度與原生畫質。"
        case .de:     return "Erhält 100% des Schwarzpegels, bewahrt vollen Kontrast und Bildqualität."
        case .en:     return "Preserves 100% black level, maintaining contrast and picture quality."
        }
    }

    public static func compareOverlay(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "소프트웨어 오버레이 필터"
        case .ja:     return "ソフトウェアオーバーレイ"
        case .zhHans: return "软件半透明遮罩"
        case .zhHant: return "軟體半透明遮罩"
        case .de:     return "Software-Overlay-Filter"
        case .en:     return "Software Overlay Filter"
        }
    }

    public static func compareOverlayDesc(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "화면에 검은 막을 씌워 블랙 레벨을 들뜨게 하고 명암비를 손상시킵니다."
        case .ja:     return "画面上に黒い膜を重ねるため、黒浮きが発生しコントラストが低下します。"
        case .zhHans: return "通过在屏幕上绘制暗色蒙版，导致纯黑发灰并破坏对比度。"
        case .zhHant: return "透過在螢幕上繪製暗色遮罩，導致純黑發灰並破壞對比度。"
        case .de:     return "Legt dunkle Fläche über den Bildschirm, hellt Schwarz auf und verringert den Kontrast."
        case .en:     return "Draws a dark window, elevating black levels and ruining contrast."
        }
    }

    public static func timeRulesSectionTitle(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "시간별 자동 설정"
        case .ja:     return "時間帯別ルール"
        case .zhHans: return "定时规则"
        case .zhHant: return "定時規則"
        case .de:     return "Zeitbasierte Regeln"
        case .en:     return "Time-Based Rules"
        }
    }

    public static func timeRuleActiveBanner(lang: AppLanguage, range: String) -> String {
        switch lang {
        case .ko:     return "시간별 규칙 적용 중 (\(range))"
        case .ja:     return "時間ルール適用中 (\(range))"
        case .zhHans: return "定时规则生效中 (\(range))"
        case .zhHant: return "定時規則生效中 (\(range))"
        case .de:     return "Zeitregel aktiv (\(range))"
        case .en:     return "Time rule active (\(range))"
        }
    }

    public static func settingsTitle(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "설정 및 자동화"
        case .ja:     return "設定と自動化"
        case .zhHans: return "偏好设置与规则"
        case .zhHant: return "偏好設定與規則"
        case .de:     return "Einstellungen & Regeln"
        case .en:     return "Preferences & Rules"
        }
    }

    public static func backButton(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "뒤로"
        case .ja:     return "戻る"
        case .zhHans: return "返回"
        case .zhHant: return "返回"
        case .de:     return "Zurück"
        case .en:     return "Back"
        }
    }

    public static func settingsGear(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "설정"
        case .ja:     return "設定"
        case .zhHans: return "设置"
        case .zhHant: return "設定"
        case .de:     return "Einstellungen"
        case .en:     return "Settings"
        }
    }

    public static func activeStatus(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "켜짐"
        case .ja:     return "オン"
        case .zhHans: return "开启"
        case .zhHant: return "開啟"
        case .de:     return "Ein"
        case .en:     return "On"
        }
    }

    public static func inactiveStatus(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "꺼짐"
        case .ja:     return "オフ"
        case .zhHans: return "关闭"
        case .zhHant: return "關閉"
        case .de:     return "Aus"
        case .en:     return "Off"
        }
    }

    public static func shortcutsAndLaunchSection(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "단축키 및 시스템"
        case .ja:     return "ショートカットとシステム"
        case .zhHans: return "快捷键与系统"
        case .zhHant: return "快速鍵與系統"
        case .de:     return "Kurzbefehle & System"
        case .en:     return "Shortcuts & System"
        }
    }

    public static func automationSection(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "자동화 규칙"
        case .ja:     return "自動化ルール"
        case .zhHans: return "自动化规则"
        case .zhHant: return "自動化規則"
        case .de:     return "Automatisierungsregeln"
        case .en:     return "Automation Rules"
        }
    }

    public static func liveCurveTitle(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "실시간 감마 변환 곡선"
        case .ja:     return "リアルタイム変換曲線"
        case .zhHans: return "实时转换曲线"
        case .zhHant: return "即時轉換曲線"
        case .de:     return "Live-Übertragungskurve"
        case .en:     return "Live Transfer Curve"
        }
    }

    public static func add(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "추가"
        case .ja:     return "追加"
        case .zhHans: return "添加"
        case .zhHant: return "新增"
        case .de:     return "Hinzufügen"
        case .en:     return "Add"
        }
    }

    public static func noTimeRules(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "설정된 시간별 규칙이 없습니다."
        case .ja:     return "スケジュールされた時間ルールはありません。"
        case .zhHans: return "暂无定时规则。"
        case .zhHant: return "暫無定時規則。"
        case .de:     return "Keine zeitbasierten Regeln."
        case .en:     return "No scheduled time rules."
        }
    }

    public static func noAppRules(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "등록된 앱 규칙이 없습니다."
        case .ja:     return "登録されたアプリルールはありません。"
        case .zhHans: return "暂无应用规则。"
        case .zhHant: return "暫無應用規則。"
        case .de:     return "Keine App-spezifischen Regeln."
        case .en:     return "No app-specific rules."
        }
    }

    public static func activeRuleBadge(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "작동 중"
        case .ja:     return "適用中"
        case .zhHans: return "生效中"
        case .zhHant: return "生效中"
        case .de:     return "Aktiv"
        case .en:     return "Active"
        }
    }

    public static func curveDescGeneral(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "일반 모드 (t = 2.5)"
        case .ja:     return "標準モード (t = 2.5)"
        case .zhHans: return "标准模式 (t = 2.5)"
        case .zhHant: return "標準模式 (t = 2.5)"
        case .de:     return "Standardmodus (t = 2.5)"
        case .en:     return "Natural Mode (t = 2.5)"
        }
    }

    public static func curveDescDocs(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "문서 · 독서 모드 (t = 4.0)"
        case .ja:     return "文書・読書モード (t = 4.0)"
        case .zhHans: return "文档·阅读模式 (t = 4.0)"
        case .zhHant: return "文件·閱讀模式 (t = 4.0)"
        case .de:     return "Dokumente & Lesen (t = 4.0)"
        case .en:     return "Docs · Reading Mode (t = 4.0)"
        }
    }

    public static func curveDescHighlights(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "하이라이트 보호 모드 (t = 6.0)"
        case .ja:     return "ハイライト保護モード (t = 6.0)"
        case .zhHans: return "高光保护模式 (t = 6.0)"
        case .zhHant: return "高光保護模式 (t = 6.0)"
        case .de:     return "Glanzlichterschutz (t = 6.0)"
        case .en:     return "Highlight Protection Mode (t = 6.0)"
        }
    }

    public static func curveDescCustom(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "커스텀 모드"
        case .ja:     return "カスタムモード"
        case .zhHans: return "自定义模式"
        case .zhHant: return "自訂模式"
        case .de:     return "Benutzerdefiniert"
        case .en:     return "Custom Mode"
        }
    }

    public static func curveDescDetailGeneral(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "전반적으로 자연스럽고 부드럽게 밝기를 낮춥니다. 웹서핑 및 일상 작업에 가장 권장됩니다."
        case .ja:     return "画面全体の輝度を自然に滑らかに下げます。ウェブ閲覧や日常の作業に最適です。"
        case .zhHans: return "全屏自然平滑地降低亮度，最适合日常办公与网页浏览。"
        case .zhHant: return "全螢幕自然平滑地降低亮度，最適合日常辦公與網頁瀏覽。"
        case .de:     return "Senkt die Helligkeit sanft und natürlich über das gesamte Display. Ideal für den Alltag."
        case .en:     return "Lowers brightness smoothly and naturally across the whole screen. Recommended for daily tasks."
        }
    }

    public static func curveDescDetailDocs(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "텍스트의 선명한 블랙을 완벽히 유지하면서 눈부신 흰 배경만 집중 감쇄합니다. 독서와 문서 작업에 적합합니다."
        case .ja:     return "文字の鮮明な黒を保ちながら、眩しい白背景だけを集中的に減衰します。読書や文書作成に最適です。"
        case .zhHans: return "在完美保留文本清晰纯黑的同时，集中衰减刺眼的纯白背景。非常适合阅读与文档处理。"
        case .zhHant: return "在完美保留文字清晰純黑的同時，集中衰減刺眼的純白背景。非常適合閱讀與文書處理。"
        case .de:     return "Bewahrt gestochen scharfen Textkontrast und dämpft gezielt grellen weißen Hintergrund. Perfekt zum Lesen."
        case .en:     return "Perfectly preserves text contrast while compressing glaring white backgrounds. Ideal for reading."
        }
    }

    public static func curveDescDetailHighlights(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "어두운 톤과 중간 톤을 최대로 보존하고 가장 밝은 극단적 광원만 눌러줍니다. 어두운 환경에 특화되어 있습니다."
        case .ja:     return "暗部と中間階調を最大限に保護し、最も眩しいハイライト部分だけを抑制します。暗い部屋での作業に特化しています。"
        case .zhHans: return "最大程度保留暗部与中间调，仅强力压制极亮的高光区域。专为暗光与夜间环境打造。"
        case .zhHant: return "最大程度保留暗部與中間調，僅強力壓制極亮的高光區域。專為暗光與夜間環境打造。"
        case .de:     return "Schützt dunkle und mittlere Töne maximal und dämpft nur extrem helle Glanzlichter. Ideal für dunkle Räume."
        case .en:     return "Maximally preserves dark and mid-tones, compressing only peak bright highlights. Tailored for dark rooms."
        }
    }

    public static func curveDescDetailCustom(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "설정된 곡선 지수에 따라 비선형 감쇄가 적용됩니다."
        case .ja:     return "設定された指数に基づいて非線形減衰が適用されます。"
        case .zhHans: return "根据设定的曲线指数应用非线性衰减。"
        case .zhHant: return "根據設定的曲線指數套用非線性衰減。"
        case .de:     return "Nichtlineare Dämpfung wird basierend auf dem eingestellten Exponenten angewendet."
        case .en:     return "Nonlinear dimming is applied based on the configured exponent."
        }
    }

    public static func ok(lang: AppLanguage) -> String {
        switch lang {
        case .ko:     return "확인"
        case .zhHans: return "确定"
        case .zhHant: return "確定"
        default:      return "OK"
        }
    }

    // MARK: - Compatibility Bridge (for isEN: Bool callers)
    private static func bridge(_ isEN: Bool) -> AppLanguage { isEN ? .en : .ko }
    public static func title(isEN: Bool) -> String { title(lang: bridge(isEN)) }
    public static func statusActive(isEN: Bool, percent: Int) -> String { statusActive(lang: bridge(isEN), percent: percent) }
    public static func statusDisabled(isEN: Bool) -> String { statusDisabled(lang: bridge(isEN)) }
    public static func reductionLabel(isEN: Bool) -> String { reductionLabel(lang: bridge(isEN)) }
    public static func preserveBlacks(isEN: Bool) -> String { preserveBlacks(lang: bridge(isEN)) }
    public static func maxWhiteLevel(isEN: Bool, percent: Int) -> String { maxWhiteLevel(lang: bridge(isEN), percent: percent) }
    public static func shortcutToggle(isEN: Bool) -> String { shortcutToggle(lang: bridge(isEN)) }
    public static func launchAtLogin(isEN: Bool) -> String { launchAtLogin(lang: bridge(isEN)) }
    public static func shortcutRecord(isEN: Bool) -> String { shortcutRecord(lang: bridge(isEN)) }
    public static func curveTypeLabel(isEN: Bool) -> String { curveTypeLabel(lang: bridge(isEN)) }
    public static func curveGeneral(isEN: Bool) -> String { curveGeneral(lang: bridge(isEN)) }
    public static func curveDocs(isEN: Bool) -> String { curveDocs(lang: bridge(isEN)) }
    public static func curveHighlights(isEN: Bool) -> String { curveHighlights(lang: bridge(isEN)) }
    public static func manualCheckHelp(isEN: Bool) -> String { manualCheckHelp(lang: bridge(isEN)) }
    public static func quitLabel(isEN: Bool) -> String { quitLabel(lang: bridge(isEN)) }
    public static func detailsTitle(isEN: Bool) -> String { detailsTitle(lang: bridge(isEN)) }
    public static func detailsSectionTitle(isEN: Bool) -> String { detailsSectionTitle(lang: bridge(isEN)) }
    public static func detailsHowItWorks(isEN: Bool) -> String { detailsHowItWorks(lang: bridge(isEN)) }
    public static func updateDownloading(isEN: Bool, ver: String) -> String { updateDownloading(lang: bridge(isEN), ver: ver) }
    public static func updateAvailable(isEN: Bool, ver: String) -> String { updateAvailable(lang: bridge(isEN), ver: ver) }
    public static func updateClickToUpdate(isEN: Bool) -> String { updateClickToUpdate(lang: bridge(isEN)) }
    public static func updateNetworkErrorTitle(isEN: Bool) -> String { updateNetworkErrorTitle(lang: bridge(isEN)) }
    public static func updateNetworkErrorMsg(isEN: Bool) -> String { updateNetworkErrorMsg(lang: bridge(isEN)) }
    public static func allDisplays(isEN: Bool) -> String { allDisplays(lang: bridge(isEN)) }
    public static func displayLabel(isEN: Bool) -> String { displayLabel(lang: bridge(isEN)) }
    public static func appRulesSectionTitle(isEN: Bool) -> String { appRulesSectionTitle(lang: bridge(isEN)) }
    public static func addRuleBtn(isEN: Bool, appName: String) -> String { addRuleBtn(lang: bridge(isEN), appName: appName) }
    public static func addRuleBtnDefault(isEN: Bool) -> String { addRuleBtnDefault(lang: bridge(isEN)) }
    public static func ruleActiveBanner(isEN: Bool, appName: String) -> String { ruleActiveBanner(lang: bridge(isEN), appName: appName) }
    public static func compareOurApp(isEN: Bool) -> String { compareOurApp(lang: bridge(isEN)) }
    public static func compareOurAppDesc(isEN: Bool) -> String { compareOurAppDesc(lang: bridge(isEN)) }
    public static func compareOverlay(isEN: Bool) -> String { compareOverlay(lang: bridge(isEN)) }
    public static func compareOverlayDesc(isEN: Bool) -> String { compareOverlayDesc(lang: bridge(isEN)) }
    public static func timeRulesSectionTitle(isEN: Bool) -> String { timeRulesSectionTitle(lang: bridge(isEN)) }
    public static func timeRuleActiveBanner(isEN: Bool, range: String) -> String { timeRuleActiveBanner(lang: bridge(isEN), range: range) }
    public static func settingsTitle(isEN: Bool) -> String { settingsTitle(lang: bridge(isEN)) }
    public static func backButton(isEN: Bool) -> String { backButton(lang: bridge(isEN)) }
    public static func settingsGear(isEN: Bool) -> String { settingsGear(lang: bridge(isEN)) }
    public static func activeStatus(isEN: Bool) -> String { activeStatus(lang: bridge(isEN)) }
    public static func inactiveStatus(isEN: Bool) -> String { inactiveStatus(lang: bridge(isEN)) }
    public static func shortcutsAndLaunchSection(isEN: Bool) -> String { shortcutsAndLaunchSection(lang: bridge(isEN)) }
    public static func automationSection(isEN: Bool) -> String { automationSection(lang: bridge(isEN)) }
    public static func liveCurveTitle(isEN: Bool) -> String { liveCurveTitle(lang: bridge(isEN)) }
    public static func add(isEN: Bool) -> String { add(lang: bridge(isEN)) }
    public static func noTimeRules(isEN: Bool) -> String { noTimeRules(lang: bridge(isEN)) }
    public static func noAppRules(isEN: Bool) -> String { noAppRules(lang: bridge(isEN)) }
    public static func activeRuleBadge(isEN: Bool) -> String { activeRuleBadge(lang: bridge(isEN)) }
    public static func curveDescGeneral(isEN: Bool) -> String { curveDescGeneral(lang: bridge(isEN)) }
    public static func curveDescDocs(isEN: Bool) -> String { curveDescDocs(lang: bridge(isEN)) }
    public static func curveDescHighlights(isEN: Bool) -> String { curveDescHighlights(lang: bridge(isEN)) }
    public static func curveDescCustom(isEN: Bool) -> String { curveDescCustom(lang: bridge(isEN)) }
    public static func ok(isEN: Bool) -> String { ok(lang: bridge(isEN)) }
}
