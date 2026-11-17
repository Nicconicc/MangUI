local _,M=...
local locales={enUS=1,zhCN=2,zhTW=3,deDE=4,frFR=5,esES=6,esMX=6,itIT=7,ptBR=8,ruRU=9,koKR=10}
local titles={"Release notes","更新日志","更新日誌","Versionshinweise","Notes de version","Notas de versión","Note di versione","Notas da versão","Примечания к версиям","업데이트 내역"}
local releases={
{904,"2026/11/17",table.concat({
    "Alt-click a character name in chat to invite them without opening a whisper.~Player and target health bars show damage trails and healing highlights. Boss encounters keep these effects on the player bar only.~Target health changes shake the main frames outside boss encounters. The center portrait follows with a short delay and a more pronounced rebound.~Party health bars show incoming heals. Target-of-target health bars retain their original color when no class color is available.~The wrench opens a categorized, searchable list of loaded add-ons and links to their settings. It includes localized descriptions, slash commands and author tips when provided by MangUITools.~The community button shows Douyin on Chinese clients and Discord elsewhere. The Chinese popup has copyable KOOK, Douyin and Afdian links, and the button can be hidden in settings.~The settings window can estimate MangUI CPU usage while open, even with system CPU profiling disabled.~On Forever, Class Skill Tracking can open the Blizzard Cooldown Manager directly when available.~The settings window now includes a localized release history.",
    "按住 Alt 左键点击聊天中的角色名即可邀请组队，不会弹出密语输入框。~玩家与目标血条新增掉血残影和回血高光，首领战只在玩家血条保留这两种效果。~非首领战中，目标血量变化会带动主框体震动；中央头像稍有滞后，并有更明显的回弹。~小队血条显示预计治疗量；无法识别职业时，目标的目标血条沿用原有颜色。~金环扳手可打开已加载的主插件列表，支持分类、搜索和打开设置，并显示多语言简介、打开命令及 MangUITools 提供的作者提示。~中文客户端的社区按钮显示抖音，其他客户端显示 Discord。中文弹窗提供可复制的 KOOK、抖音直播和爱发电链接，按钮可在设置中关闭。~设置窗口打开时可显示 MangUI 的 CPU 用量，即使关闭系统 CPU 记录也可查看估算值。~无限服职业技能监控可在官方接口可用时直接打开暴雪冷却管理器。~设置窗口新增多语言更新日志，可查看历次发布内容。",
    "按住 Alt 並以左鍵點擊聊天中的角色名稱即可邀請組隊，不會開啟密語輸入框。~玩家與目標血條新增掉血殘影和回血高光，首領戰只保留玩家血條的效果。~非首領戰中，目標血量變動會帶動主框體震動，中央頭像略為延後並明顯回彈。~小隊血條顯示預計治療量，無法辨識職業時，目標的目標血條沿用原有色彩。~金環扳手可開啟已載入的主插件清單，支援分類、搜尋及開啟設定，並顯示多語簡介、指令及 MangUITools 提供的作者提示。~中文用戶端的社群按鈕顯示抖音，其他用戶端顯示 Discord。中文彈窗提供可複製的 KOOK、抖音直播和愛發電連結，按鈕可在設定中關閉。~設定視窗開啟時可顯示 MangUI 的 CPU 用量，即使關閉系統 CPU 記錄也能查看估算值。~無限服職業技能監控可在官方介面可用時直接開啟暴雪冷卻管理器。~設定視窗新增多語更新日誌，可查看歷次發行內容。",
    "Alt-Linksklick auf einen Charakternamen im Chat lädt ihn ein, ohne ein Flüsterfeld zu öffnen.~Lebensleisten von Spieler und Ziel zeigen Schadensspuren und Heilungseffekte. Bei Bosskämpfen bleiben die Effekte auf die Spielerleiste beschränkt.~Außerhalb von Bosskämpfen rütteln Änderungen der Ziellebenspunkte am Hauptfenster. Das mittlere Porträt folgt leicht verzögert und schwingt deutlicher nach.~Gruppenleisten zeigen eingehende Heilung. Die Lebensleiste des Zielziels behält ohne erkennbare Klasse ihre ursprüngliche Farbe.~Der Schraubenschlüssel öffnet eine durchsuchbare, kategorisierte Liste geladener Add-ons mit Einstellungen, mehrsprachigen Beschreibungen, Befehlen und Hinweisen aus MangUITools.~Die Community-Schaltfläche zeigt in chinesischen Clients Douyin, andernorts Discord. Das chinesische Fenster bietet kopierbare Links zu KOOK, Douyin und Afdian. Die Schaltfläche lässt sich ausblenden.~Bei geöffneten Einstellungen kann MangUI seine CPU-Nutzung auch ohne Systemprofilierung schätzen.~Auf Forever kann die Klassenfähigkeitsverfolgung den Blizzard-Abklingzeitmanager direkt öffnen, sofern verfügbar.~Die Einstellungen enthalten einen mehrsprachigen Versionsverlauf.",
    "Alt-clic gauche sur un nom dans le chat permet d’inviter le personnage sans ouvrir de champ de chuchotement.~Les barres de vie du joueur et de la cible affichent une traînée de dégâts et un effet de soin. Face aux boss, seule la barre du joueur conserve ces effets.~Hors combat de boss, les variations de vie de la cible font vibrer les cadres principaux. Le portrait central suit avec un léger retard et un rebond plus marqué.~Les barres de groupe affichent les soins à venir. La barre de la cible de la cible conserve sa couleur d’origine si la classe est inconnue.~La clé ouvre une liste des extensions chargées avec catégories, recherche, accès aux réglages, descriptions traduites, commandes et conseils de MangUITools.~Le bouton de communauté affiche Douyin sur les clients chinois et Discord ailleurs. Le panneau chinois propose des liens copiables vers KOOK, Douyin et Afdian. Le bouton peut être masqué.~La fenêtre de réglages peut estimer l’utilisation CPU de MangUI pendant qu’elle est ouverte, même si le profilage système est désactivé.~Sur Forever, le suivi des techniques de classe peut ouvrir directement le gestionnaire de temps de recharge de Blizzard lorsqu’il est disponible.~Les réglages comprennent un historique des versions en plusieurs langues.",
    "Alt-clic izquierdo en un nombre del chat invita al personaje sin abrir el cuadro de susurro.~Las barras de salud del jugador y del objetivo muestran rastros de daño y destellos de sanación. En combates contra jefes, los efectos se mantienen solo en la barra del jugador.~Fuera de combates contra jefes, los cambios de salud del objetivo sacuden los marcos principales. El retrato central los sigue con un ligero retraso y un rebote más visible.~Las barras del grupo muestran la sanación entrante. La barra del objetivo del objetivo conserva su color original si no se reconoce la clase.~La llave inglesa abre una lista de complementos cargados con categorías, búsqueda, acceso a sus ajustes, descripciones traducidas, comandos y consejos de MangUITools.~El botón de comunidad muestra Douyin en los clientes chinos y Discord en los demás. El panel chino ofrece enlaces copiables de KOOK, Douyin y Afdian. El botón se puede ocultar.~La ventana de ajustes puede estimar el uso de CPU de MangUI mientras está abierta, incluso con el perfilado del sistema desactivado.~En Forever, el seguimiento de facultades de clase puede abrir el gestor de reutilización de Blizzard si está disponible.~Los ajustes incluyen un historial de versiones en varios idiomas.",
    "Alt-clic sinistro su un nome in chat invita il personaggio senza aprire il campo dei sussurri.~Le barre della salute del giocatore e del bersaglio mostrano scie dei danni e bagliori delle cure. Durante gli scontri con i boss gli effetti restano solo sulla barra del giocatore.~Fuori dagli scontri con i boss, le variazioni di salute del bersaglio fanno oscillare i riquadri principali. Il ritratto centrale segue con un lieve ritardo e un rimbalzo più visibile.~Le barre del gruppo mostrano le cure in arrivo. La barra del bersaglio del bersaglio mantiene il colore originale se la classe è sconosciuta.~La chiave inglese apre l’elenco degli add-on caricati con categorie, ricerca, impostazioni, descrizioni tradotte, comandi e suggerimenti di MangUITools.~Il pulsante della community mostra Douyin sui client cinesi e Discord sugli altri. Il pannello cinese offre link copiabili per KOOK, Douyin e Afdian. Il pulsante può essere nascosto.~La finestra delle impostazioni aperta può stimare l’uso della CPU di MangUI anche con la profilazione di sistema disattivata.~Su Forever, il monitoraggio delle abilità di classe può aprire direttamente il gestore dei tempi di recupero di Blizzard quando disponibile.~Le impostazioni includono una cronologia delle versioni in più lingue.",
    "Alt-clique esquerdo em um nome no bate-papo convida o personagem sem abrir o campo de sussurro.~As barras de vida do jogador e do alvo mostram rastros de dano e brilhos de cura. Em lutas contra chefes, os efeitos ficam apenas na barra do jogador.~Fora de lutas contra chefes, mudanças na vida do alvo fazem os quadros principais tremerem. O retrato central acompanha com um pequeno atraso e um rebote mais visível.~As barras do grupo mostram a cura prevista. A barra do alvo do alvo mantém a cor original quando a classe não é identificada.~A chave inglesa abre a lista de addons carregados com categorias, pesquisa, acesso às configurações, descrições traduzidas, comandos e dicas do MangUITools.~O botão da comunidade mostra Douyin nos clientes chineses e Discord nos demais. O painel chinês oferece links copiáveis do KOOK, Douyin e Afdian. O botão pode ser ocultado.~A janela de configurações pode estimar o uso de CPU do MangUI enquanto estiver aberta, mesmo com o perfilamento do sistema desativado.~No Forever, o rastreamento de habilidades de classe pode abrir diretamente o gerenciador de recargas da Blizzard quando disponível.~As configurações incluem um histórico de versões em vários idiomas.",
    "Alt + щелчок левой кнопкой мыши по имени в чате приглашает персонажа в группу без открытия поля шёпота.~Полоски здоровья игрока и цели показывают следы урона и вспышки исцеления. В бою с боссом эффекты остаются только на полоске игрока.~Вне боёв с боссами изменения здоровья цели встряхивают основные рамки. Центральный портрет движется с небольшим запаздыванием и заметнее качается при остановке.~На полосках здоровья группы видно ожидаемое исцеление. Если класс неизвестен, полоска здоровья цели цели сохраняет исходный цвет.~Кнопка с ключом открывает список загруженных дополнений с категориями, поиском, доступом к настройкам, переведёнными описаниями, командами и подсказками из MangUITools.~Кнопка сообщества показывает Douyin в китайских клиентах и Discord в остальных. В китайской панели можно копировать ссылки на KOOK, Douyin и Afdian. Кнопку можно скрыть.~В открытом окне настроек можно увидеть оценку нагрузки MangUI на ЦП даже при отключённом системном профилировании.~В Forever отслеживание классовых способностей может напрямую открывать менеджер восстановления Blizzard, когда он доступен.~В настройках появилась многоязычная история версий.",
    "채팅에서 캐릭터 이름을 Alt+왼쪽 클릭하면 귓속말 입력창을 열지 않고 초대합니다.~플레이어와 대상 생명력 바에 피해 잔상과 치유 강조 효과가 표시됩니다. 우두머리 전투에서는 플레이어 바에만 적용됩니다.~우두머리 전투가 아닐 때 대상 생명력이 변하면 기본 프레임이 흔들립니다. 중앙 초상화는 조금 늦게 따라오며 더 뚜렷하게 반동합니다.~파티 생명력 바에 받을 치유량이 표시됩니다. 직업을 확인할 수 없으면 대상의 대상 생명력 바는 원래 색상을 유지합니다.~렌치 버튼에서 로드된 애드온을 분류하고 검색하며 설정을 열 수 있습니다. 번역된 설명, 명령어 및 MangUITools의 제작자 팁도 표시합니다.~중국어 클라이언트의 커뮤니티 버튼은 Douyin을, 그 외에는 Discord를 표시합니다. 중국어 팝업에서 KOOK, Douyin, Afdian 링크를 복사할 수 있으며 버튼을 숨길 수도 있습니다.~시스템 프로파일링을 꺼도 설정 창이 열린 동안 MangUI의 CPU 사용량을 추정할 수 있습니다.~Forever에서 직업 기술 추적이 사용 가능한 경우 블리자드 재사용 대기시간 관리자를 바로 열 수 있습니다.~설정에 다국어 업데이트 내역이 추가되었습니다.",
},"|")},
{861,"2026/11/16","Improved first-time Blizzard Essential Cooldown import on Forever.~Unconfigured characters keep waiting for the cooldown data at login and are marked as set up only after a successful import.|优化无限服职业技能监控首次同步。~未配置的角色登录后会等待冷却数据就绪，成功导入暴雪主要技能后才标记完成。|改善無限服首次冷卻匯入，等資料就緒後才標記完成。|Erstimport der Abklingzeiten auf Forever wartet auf verfügbare Daten.|Sur Forever, le premier import attend que les données de recharge soient prêtes.|En Forever, la primera importación espera a que estén disponibles los datos de reutilización.|Su Forever, la prima importazione attende i dati dei tempi di recupero.|Em Forever, a primeira importação aguarda os dados de recarga.|На Forever первый импорт ждёт готовности данных о восстановлении.|Forever의 첫 재사용 대기시간 가져오기는 데이터가 준비될 때까지 기다립니다."},
{860,"2026/11/16","Added an option to keep the combat entry alert visible until combat ends.~Fixed move mode being blocked by an error when configuring custom pet buffs.|新增战斗中常驻提示选项。开启后，入战提示会保留到脱战，再播放离战提示。~修复配置宠物自定义增益时，点击解锁移动模式报错并遮挡操作的问题。|新增戰鬥中常駐提示選項，修正設定寵物自訂增益時的移動模式。|Kampfhinweis kann sichtbar bleiben~Verschiebemodus bei eigenen Begleiterbuffs korrigiert.|L’alerte peut rester visible en combat~correction du mode déplacement avec les buffs personnalisés du familier.|La alerta puede permanecer visible en combate~corregido el modo de movimiento con beneficios personalizados de mascota.|L’avviso può restare visibile in combattimento~corretto lo spostamento con i benefici personalizzati del famiglio.|O alerta pode ficar visível em combate~corrigido o modo de mover com bônus personalizados do mascote.|Оповещение может оставаться в бою~исправлено перемещение при настройке эффектов питомца.|전투 알림 유지 옵션을 추가하고 소환수 강화 효과 설정 중 이동 모드를 수정했습니다."},
{858,"2026/11/16","Press the marking shortcut in combat to open the target-marker wheel at the cursor and set or clear a mark with one click.~The mouse controls module and cursor highlight have separate toggles, so shortcuts can stay enabled with the highlight hidden.~On Forever, Class Skill Tracking can import learned Blizzard Essential Cooldowns and follow Blizzard's layout. Sync preserves manual entries and keybinds.~Drag icons directly in the previews of six tracking pages to reorder them. Timers use whole numbers and show durations above one minute in whole minutes. Fixed overlapping timers and interrupted raid vulnerability updates.~Manually entered spell IDs follow the currently learned rank for cooldowns and match active auras by their localized name.~Hover over the top-left corner for online friends and guild members. The scrollable panel uses class colors and offers whisper and invite actions.~Added bag free slots and equipment durability buttons. Hover over the anvil for a slot-by-slot breakdown. The gold-framed dice icon sits to its left.~Targeting the group leader replaces the portrait ornament with the original leader icon. The party indicator sits slightly lower.~With hover-to-show enabled, the experience bar appears when you hover over its position and fades out 10 seconds after you move away.~Added an option to maximize ground vegetation density, off by default.|战斗中按标记快捷键可在鼠标位置打开目标标记轮盘，点击即可为当前目标设置或清除标记。~鼠标功能和光圈独立开关，隐藏光圈后仍可使用已启用的快捷功能。~无限服职业技能监控可导入已学的暴雪主要技能，并跟随官方布局同步。保留手动条目和已有快捷键。~六个监控页面都可直接拖动预览图标排序。倒计时统一用整数，超过一分钟显示整分钟和 m。修复倒计时重叠和团队易伤刷新中断。~手动输入法术 ID 后，技能冷却跟随当前已学的同名法术等级，光环按客户端名称匹配实际效果。~屏幕左上角可悬停查看在线好友与公会成员，名单支持滚动、职业着色、密语及邀请。~新增装备耐久度和背包空位按钮，悬停铁砧可查看各部位耐久度。金框骰子位于铁砧左侧。~选中队长时，目标头像装饰切换为放大的原版队长图标，小队队长图标略微下移。~开启悬停显示后，鼠标移到经验条位置即可显示，移开 10 秒后淡出。~新增最大化地面植被密度选项，默认关闭。|新增好友與公會面板、耐久度和背包按鈕，改善冷卻匯入、監控倒數、法術等級配對及隊長頭像裝飾。|Freundes- und Gildenliste, Haltbarkeit und Taschen~verbesserter Abklingzeitimport, Timer, Zauberränge und Anführerporträts.|Liste d’amis et de guilde, durabilité et sacs~import des recharges, minuteries, rangs de sorts et portraits des chefs améliorés.|Panel de amigos y hermandad, durabilidad y bolsas~mejoras en importación, temporizadores, rangos y retratos de líder.|Pannello amici e gilda, integrità e borse~migliorati importazione, timer, gradi delle magie e ritratti dei capigruppo.|Painel de amigos e guilda, durabilidade e bolsas~melhorias na importação, nos cronômetros, nos graus de feitiço e nos retratos de líder.|Панель друзей и гильдии, прочность и сумки~улучшены импорт, таймеры, ранги заклинаний и портреты лидеров.|친구·길드 패널, 내구도와 가방 버튼을 추가하고 재사용 대기시간 가져오기, 타이머, 주문 등급 및 파티장 초상화를 개선했습니다."},
{810,"2026/11/13","Added an in-combat keybind that opens the target-marker wheel at the cursor. Out of combat, double-click a world unit to open the wheel.~Added always-visible system menu icons and adjustable icon spacing, reflected in the preview.~Improved party portrait refresh when members connect or change state, and fixed odd-numbered rogue combo-point model transitions on Forever.|新增战斗标记快捷键，在鼠标位置直接打开轮盘。脱战时双击场景单位也可打开轮盘。~系统菜单新增图标常驻与间距设置，预览同步反映布局。~改善小队头像刷新时机，修复无限服潜行者奇数连击点模型的过渡显示。|新增戰鬥目標標記輪盤和系統選單圖示設定，改善小隊頭像更新。|Zielmarkierungsrad im Kampf und Menüoptionen~Gruppenporträts aktualisieren zuverlässiger.|Roue de marquage en combat, options du menu système et meilleure actualisation des portraits de groupe.|Rueda de marcas en combate, opciones del menú del sistema y mejor actualización de retratos de grupo.|Ruota dei contrassegni in combattimento, opzioni del menu di sistema e aggiornamento dei ritratti del gruppo migliorato.|Roda de marcas em combate, opções do menu do sistema e atualização melhorada dos retratos do grupo.|Колесо меток в бою, настройки системного меню и улучшенное обновление портретов группы.|전투 대상 징표 휠과 시스템 메뉴 아이콘 옵션을 추가하고 파티 초상화 갱신을 개선했습니다."},
{792,"2026/11/10","Added an option to disable system CPU profiling.~Optimized aura and skill refreshes by batching frequent combat events, and improved handling of protected aura data.~Adjusted party frame updates in raids to reduce the cost of hidden status indicators.|新增关闭系统 CPU 性能记录的选项。~合并战斗中的密集更新事件，优化技能与光环监控，并改进受保护光环数据的处理。~优化团队战斗中的小队框体刷新，减少隐藏状态提示带来的开销。|新增 CPU 效能分析開關，最佳化戰鬥中的光環及技能監控。|Option für CPU-Profiling~Aura- und Fähigkeitsverfolgung im Kampf optimiert.|Option de profilage CPU~suivi des auras et techniques optimisé en combat.|Opción de perfilado de CPU y seguimiento de auras y facultades optimizado en combate.|Opzione per il profiling CPU e monitoraggio di aure e abilità ottimizzato in combattimento.|Opção de perfilamento de CPU e rastreamento de auras e habilidades otimizado em combate.|Настройка профилирования ЦП~оптимизировано отслеживание аур и способностей в бою.|CPU 프로파일링 옵션을 추가하고 전투 중 오라와 기술 추적을 최적화했습니다."},
{785,"2026/11/08","Added individually configurable mouse shortcuts for unit menus, target markers, invites, and focus.~Added a separate mana bar above the player health bar for druids in cat and bear forms, including support for clients with protected mana data.~Improved target-change refresh and clipped bar sweep effects to the fill area.|加入可分别开关的鼠标快捷功能，包括单位菜单、目标标记、邀请和焦点。~德鲁伊在猎豹与熊形态时可在生命条上方查看独立法力条，并兼容法力数据受保护的客户端。~优化目标切换刷新，让血量与资源条的扫光贴合实际填充范围。|新增獨立滑鼠快捷功能及獵豹、熊形態法力條，改善目標更新。|Separate Mausaktionen und Druiden-Manaleiste in Katzen- und Bärengestalt~Zielaktualisierung verbessert.|Raccourcis souris indépendants, barre de mana du druide en félin et en ours, et meilleure actualisation de la cible.|Atajos de ratón independientes, barra de maná de druida en felino y oso, y mejor actualización del objetivo.|Scorciatoie del mouse indipendenti, barra del mana del druido in forma felina e d’orso e aggiornamento del bersaglio migliorato.|Atalhos independentes do mouse, barra de mana do druida em forma felina e de urso e atualização de alvo melhorada.|Отдельные команды мыши, полоска маны друида в облике кошки и медведя, улучшенное обновление цели.|개별 마우스 단축 동작과 표범·곰 변신 중 드루이드 마나 바를 추가하고 대상 갱신을 개선했습니다."},
{765,"2026/11/07","Added party member tooltips with area information.~Added player stance tracking by name or spell ID. Inactive stances hide without taking up space.~Added horizontal cast bar scaling that preserves the end caps and center ornament, and corrected the start of the cast fill.~Added the Simplified Chinese client archive override option, applied after restarting the game.|小队成员鼠标提示会显示所在区域。~新增玩家姿态监控，可按名称或法术 ID 设置，未激活时隐藏且不占位。~施法条可横向缩放，保留两端和中央装饰，并修正读条起始填充。~简体中文客户端新增重启后生效的反和谐选项。|新增隊員提示、姿態監控及施法條橫向縮放。|Gruppen-Tooltips, Haltungsverfolgung und horizontale Zauberleistenskalierung.|Info-bulles des équipiers, suivi des postures et mise à l’échelle horizontale de la barre d’incantation.|Avisos de miembros del grupo, seguimiento de actitudes y escala horizontal de la barra de lanzamiento.|Descrizioni dei membri, monitoraggio delle posture e scala orizzontale della barra di lancio.|Dicas dos membros do grupo, rastreamento de posturas e escala horizontal da barra de lançamento.|Подсказки участников группы, отслеживание стоек и масштабирование полосы произнесения по ширине.|파티원 툴팁, 태세 추적 및 시전 바 가로 크기 설정을 추가했습니다."},
{757,"2026/11/06","Added player buff and usable proc tracking, plus an invert-display option on supported skill and aura entries.~Party frames can display buffs with cooldown sweeps; countdown numbers are hidden.~Interrupted or canceled casts turn red, shake briefly, and fade out.~Restored combat and boss encounter loading conditions for equipment tracking.|新增玩家增益、可用触发技能监控，部分技能及光环条目支持反转显示效果。~小队框体可显示成员增益，保留冷却扫光并隐藏数字。~施法被打断或取消时，施法条变红、短暂震动后淡出。~恢复装备触发监控的战斗中和首领战中加载条件。|新增玩家增益、可用觸發技能與隊伍增益監控，加入施法中斷動畫，恢復裝備監控的戰鬥篩選。|Spieler- und Gruppenbuffs, auslösbare Fähigkeiten und Abbruchanimation~Kampffilter für Ausrüstung wiederhergestellt.|Suivi des améliorations du joueur et du groupe, procs utilisables et animation d’interruption~filtres de combat rétablis pour l’équipement.|Beneficios del jugador y del grupo, activaciones utilizables y animación de interrupción~restaurados los filtros de combate del equipo.|Benefici del giocatore e del gruppo, effetti utilizzabili e animazione di interruzione~ripristinati i filtri di combattimento dell’equipaggiamento.|Bônus do jogador e grupo, efeitos utilizáveis e animação de interrupção~filtros de combate do equipamento restaurados.|Эффекты игрока и группы, доступные срабатывания и анимация прерывания~восстановлены боевые фильтры экипировки.|플레이어·파티 강화 효과와 사용 가능한 발동 추적, 시전 중단 연출을 추가하고 장비 추적 전투 필터를 복원했습니다."},
{745,"2026/11/06","Improved debuff and missing-buff indicators on Forever. Hidden entries no longer leave gaps.~Added optional sounds for cast stages and unified the blue M medallion across clients.~Fixed tooltip anchoring errors when hovering restricted missing-buff icons.|改进无限服目标减益、缺失增益的监控显示，隐藏条目不再占位。~加入可关闭的施法分段音效，统一各客户端的蓝色 M 徽章。~修复悬停受限的缺失增益图标时出现的提示框锚点报错。|改善減益及缺少增益提示，新增施法分段音效並統一藍色 M 圖示。|Verbesserte Debuff- und Fehlbuffanzeigen, Zauberstufentöne und einheitliches blaues M-Symbol.|Indicateurs de malus et d’améliorations manquantes affinés, sons des étapes d’incantation et icône M bleue unifiée.|Indicadores de perjuicios y beneficios ausentes mejorados, sonidos por etapa de lanzamiento e icono M azul unificado.|Indicatori di penalità e benefici mancanti migliorati, suoni delle fasi di lancio e icona M blu unificata.|Indicadores de penalidades e bônus ausentes melhorados, sons das etapas de lançamento e ícone M azul unificado.|Улучшены индикаторы отрицательных и отсутствующих эффектов~звуки стадий произнесения и единый синий значок M.|약화 효과 및 강화 효과 누락 표시를 개선하고 시전 단계 소리와 파란색 M 아이콘을 적용했습니다."},
{731,"2026/11/05","Fixed protected aura button errors in Forever equipment and proc tracking.|修复无限服装备触发监控访问受保护光环按钮时报错。|修正無限服裝備觸發監控存取受保護光環按鈕時的錯誤。|Fehler mit geschützten Auraschaltflächen bei der Ausrüstungsverfolgung auf Forever korrigiert.|Correction des erreurs de boutons d’aura protégés dans le suivi d’équipement sur Forever.|Corregidos errores de botones de aura protegidos en el seguimiento de equipo en Forever.|Corretti gli errori relativi ai pulsanti aura protetti nel monitoraggio dell’equipaggiamento su Forever.|Corrigidos erros de botões de aura protegidos no rastreamento de equipamento em Forever.|Исправлены ошибки защищённых кнопок аур при отслеживании экипировки на Forever.|Forever 장비 효과 추적에서 보호된 오라 버튼 관련 오류를 수정했습니다."},
{729,"2026/11/04","Added stage effects to normal casts, channels, and melee and ranged swing bars.~Editor undo history is retained per module when switching categories or selecting other elements.~Retail rogue combo points support seven points, with green accents on the sixth and seventh points.~Character monitor settings check character and class ownership before using copied data.|普通施法、引导、近战及远程攻击条新增分段特效。~编辑器按模块保留撤销记录，切换子分类或选中其他元素后仍可撤销。~正式服潜行者支持七个连击点，第六和第七点使用绿色。~角色监控配置增加角色和职业归属校验，防止复制存档后覆盖其他角色的监控。|新增施法與攻擊條分段特效、獨立模組復原、盜賊七連擊點支援及監控設定角色歸屬檢查。|Stufeneffekte für Zauber und Angriffe, Rückgängig je Modul, sieben Combopunkte und Charakterprüfung für Einstellungen.|Effets par étape pour incantations et attaques, annulation par module, sept points de combo et vérification du personnage des réglages.|Efectos por etapa de lanzamiento y ataque, deshacer por módulo, siete puntos de combo y verificación de ajustes por personaje.|Effetti per fasi di lancio e attacco, annullamento per modulo, sette punti combo e verifica del personaggio per le impostazioni.|Efeitos por etapa de lançamento e ataque, desfazer por módulo, sete pontos de combo e verificação do personagem nas configurações.|Эффекты стадий произнесения и атак, отмена по модулям, семь приёмов в серии и проверка владельца настроек.|시전·공격 바 단계 효과, 모듈별 실행 취소, 도적 연계 점수 7개 지원과 캐릭터별 설정 검사를 추가했습니다."},
{720,"2026/10/26","Redesigned Retail class resources with specialization-specific artwork and effects.~Added Vengeance Soul Fragments with real aura stack counts and an optional hide-without-target setting for class power points.~Improved empowered cast segments and added configurable abbreviated number formatting.|重制正式服职业资源，按职业和专精应用对应图案与特效。~加入复仇恶魔猎手灵魂残片，按实际光环层数显示。职业资源点新增无目标时隐藏的选项。~改进蓄力施法分段表现，并加入可配置的数值简写。|重製正式服職業資源，新增復仇靈魂裂片，改善蓄力施法及數值簡寫。|Retail-Klassenressourcen überarbeitet, Rachsucht-Seelenfragmente ergänzt, aufgeladene Zauber und Zahlenformat verbessert.|Ressources de classe Retail revues, fragments d’âme de Vengeance ajoutés, sorts renforcés et affichage des nombres améliorés.|Renovados los recursos de clase de Retail, añadidos los fragmentos de alma de Venganza y mejorados los lanzamientos potenciados y el formato numérico.|Risorse di classe Retail rinnovate, frammenti d’anima di Vendetta aggiunti, magie potenziate e numeri migliorati.|Recursos de classe do Retail reformulados, fragmentos de alma de Vingança adicionados, conjurações potencializadas e números melhorados.|Переработаны ресурсы классов Retail, добавлены фрагменты души «Мести», улучшены усиленные заклинания и формат чисел.|본 서버 직업 자원을 개편하고 복수 영혼 파편을 추가했으며, 강화 시전과 숫자 표기를 개선했습니다."},
{700,"2026/10/25","Earliest package in the local archive.|本地归档中最早的版本。|本機封存中最早的版本。|Ältestes Paket im lokalen Archiv.|Plus ancien paquet de l’archive locale.|Paquete más antiguo del archivo local.|Pacchetto più vecchio nell’archivio locale.|Pacote mais antigo no arquivo local.|Самый ранний пакет в локальном архиве.|로컬 보관함에서 가장 오래된 패키지입니다."},
}
M.ReleaseNotes={titles=titles,locales=locales,releases=releases}

function M.ReleaseNotes.Attach(window)
    local W=M.Widgets
    local button=CreateFrame("Button",nil,window)
    button:SetSize(30,27)
    button:SetPoint("TOPRIGHT",window,"TOPRIGHT",-23,-33)
    button:SetFrameStrata("FULLSCREEN_DIALOG")
    button:SetFrameLevel(20)
    local icon=button:CreateTexture(nil,"ARTWORK")
    icon:SetPoint("CENTER")
    icon:SetSize(23,23)
    icon:SetTexture("Interface\\Icons\\INV_Scroll_03")
    local ring=button:CreateTexture(nil,"OVERLAY")
    ring:SetAllPoints(icon)
    ring:SetTexture(icon:GetTexture())
    ring:SetBlendMode("ADD")
    ring:SetAlpha(0)
    local dismiss=CreateFrame("Button",nil,window)
    dismiss:SetAllPoints(UIParent)
    dismiss:SetFrameStrata("FULLSCREEN_DIALOG")
    dismiss:SetFrameLevel(1)
    dismiss:RegisterForClicks("AnyDown")
    dismiss:Hide()
    local panel=W.Panel(window)
    panel:SetPoint("TOPRIGHT",button,"BOTTOMRIGHT",0,-3)
    panel:SetSize(460,385)
    panel:SetFrameStrata("FULLSCREEN_DIALOG")
    panel:SetFrameLevel(10)
    panel:SetBackdropColor(.075,.065,.06,.99)
    panel:SetBackdropBorderColor(.65,.49,.29,1)
    panel:EnableMouse(true)
    panel:Hide()

    local title=W.Label(panel,"",15)
    title:SetPoint("TOPLEFT",14,-12)
    title:SetTextColor(1,.82,.28)
    local scroll,body=W.Scroll(panel)
    scroll:SetPoint("TOPLEFT",12,-38)
    scroll:SetPoint("BOTTOMRIGHT",-32,12)
    body:SetWidth(416)
    local rows={}
    local headingGap,paragraphGap,lineGap=10,8,3
    local bulletIndent=16
    local language,renderedCount
    local pinned,away=false,0
    local function Populate()
        local index=locales[M:EffectiveLanguage()] or 1
        if language==index and renderedCount==#releases then return end
        title:SetText(titles[index])
        local y=0
        for i,release in ipairs(releases) do
            local row=rows[i]
            if not row then
                row={version=W.Label(body,"",13),date=W.Label(body,"",13),paragraphs={}}
                row.version:SetTextColor(1,.82,.32)
                row.date:SetTextColor(.68,.68,.68)
                rows[i]=row
            end
            local version,date,summary=unpack(release,1,3)
            local translation=1
            local first
            for entry in summary:gmatch("[^|]+") do
                first=first or entry
                if translation==index then first=entry;break end
                translation=translation+1
            end
            row.version:ClearAllPoints()
            row.version:SetPoint("TOPLEFT",2,-y)
            row.version:SetText(("v%d"):format(version))
            row.date:ClearAllPoints()
            row.date:SetPoint("LEFT",row.version,"RIGHT",6,0)
            row.date:SetText(date)
            y=y+math.max(row.version:GetStringHeight(),row.date:GetStringHeight())+headingGap
            local count=0
            for paragraph in (first or ""):gmatch("[^~]+") do
                count=count+1
                local part=row.paragraphs[count]
                if not part then
                    part={dot=W.Label(body,"·",12),text=W.Label(body,"",12)}
                    part.text:SetWidth(410-bulletIndent)
                    part.text:SetWordWrap(true)
                    part.text:SetSpacing(lineGap)
                    row.paragraphs[count]=part
                end
                part.dot:ClearAllPoints()
                part.dot:SetPoint("TOPLEFT",2,-y)
                part.text:ClearAllPoints()
                part.text:SetPoint("TOPLEFT",2+bulletIndent,-y)
                part.text:SetText(paragraph)
                part.dot:Show()
                part.text:Show()
                y=y+part.text:GetStringHeight()+paragraphGap
            end
            for j=count+1,#row.paragraphs do
                row.paragraphs[j].dot:Hide()
                row.paragraphs[j].text:Hide()
            end
            y=y+12
        end
        body:SetHeight(math.max(1,y))
        scroll:SetVerticalScroll(0)
        language,renderedCount=index,#releases
    end
    local function Open()
        away=0
        dismiss:Show()
        panel:Show()
        Populate()
    end
    local function Close()
        pinned=false
        panel:Hide()
        dismiss:Hide()
    end
    dismiss:SetScript("OnClick",Close)
    button:SetScript("OnEnter",function()ring:SetAlpha(.25);Open()end)
    button:SetScript("OnLeave",function()ring:SetAlpha(0)end)
    button:SetScript("OnClick",function()
        if pinned then Close()
        else pinned=true;Open() end
    end)
    panel:SetScript("OnUpdate",function(self,elapsed)
        Populate()
        if pinned or button:IsMouseOver() or self:IsMouseOver() then away=0;return end
        away=away+elapsed
        if away>.35 then Close() end
    end)
    window:HookScript("OnHide",Close)
end
