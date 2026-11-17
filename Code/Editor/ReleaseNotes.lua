local _,M=...
local locales={enUS=1,zhCN=2,zhTW=3,deDE=4,frFR=5,esES=6,esMX=6,itIT=7,ptBR=8,ruRU=9,koKR=10}
local titles={"Release notes","更新日志","更新日誌","Versionshinweise","Notes de version","Notas de versión","Note di versione","Notas da versão","Примечания к версиям","업데이트 내역"}
local releases={
{861,860,"Improved initial Blizzard cooldown import on Forever; waits for data before marking setup complete.|优化无限服首次冷却导入，等待数据就绪后再标记完成。|改善無限服首次冷卻匯入，等資料就緒後才標記完成。|Erstimport der Abklingzeiten auf Forever wartet auf verfügbare Daten.|Sur Forever, le premier import attend que les données de recharge soient prêtes.|En Forever, la primera importación espera a que estén disponibles los datos de reutilización.|Su Forever, la prima importazione attende i dati dei tempi di recupero.|Em Forever, a primeira importação aguarda os dados de recarga.|На Forever первый импорт ждёт готовности данных о восстановлении.|Forever의 첫 재사용 대기시간 가져오기는 데이터가 준비될 때까지 기다립니다."},
{860,858,"Added an option to keep the combat alert visible in combat; fixed move mode with custom pet buffs.|新增战斗中常驻提示选项，修复配置宠物自定义增益时的移动模式。|新增戰鬥中常駐提示選項，修正設定寵物自訂增益時的移動模式。|Kampfhinweis kann sichtbar bleiben; Verschiebemodus bei eigenen Begleiterbuffs korrigiert.|L’alerte peut rester visible en combat ; correction du mode déplacement avec les buffs personnalisés du familier.|La alerta puede permanecer visible en combate; corregido el modo de movimiento con beneficios personalizados de mascota.|L’avviso può restare visibile in combattimento; corretto lo spostamento con i benefici personalizzati del famiglio.|O alerta pode ficar visível em combate; corrigido o modo de mover com bônus personalizados do mascote.|Оповещение может оставаться в бою; исправлено перемещение при настройке эффектов питомца.|전투 알림 유지 옵션을 추가하고 소환수 강화 효과 설정 중 이동 모드를 수정했습니다."},
{858,810,"Added the friends and guild panel, durability and bag buttons; improved cooldown import, tracking timers, spell ranks and leader portraits.|新增好友与公会面板、耐久度和背包按钮，改进冷却导入、监控倒计时、法术等级匹配及队长头像装饰。|新增好友與公會面板、耐久度和背包按鈕，改善冷卻匯入、監控倒數、法術等級配對及隊長頭像裝飾。|Freundes- und Gildenliste, Haltbarkeit und Taschen; verbesserter Abklingzeitimport, Timer, Zauberränge und Anführerporträts.|Liste d’amis et de guilde, durabilité et sacs ; import des recharges, minuteries, rangs de sorts et portraits des chefs améliorés.|Panel de amigos y hermandad, durabilidad y bolsas; mejoras en importación, temporizadores, rangos y retratos de líder.|Pannello amici e gilda, integrità e borse; migliorati importazione, timer, gradi delle magie e ritratti dei capigruppo.|Painel de amigos e guilda, durabilidade e bolsas; melhorias na importação, nos cronômetros, nos graus de feitiço e nos retratos de líder.|Панель друзей и гильдии, прочность и сумки; улучшены импорт, таймеры, ранги заклинаний и портреты лидеров.|친구·길드 패널, 내구도와 가방 버튼을 추가하고 재사용 대기시간 가져오기, 타이머, 주문 등급 및 파티장 초상화를 개선했습니다."},
{810,792,"Added the combat target-marker wheel and system menu icon options; improved party portrait refresh.|新增战斗目标标记轮盘和系统菜单图标设置，改进小队头像刷新。|新增戰鬥目標標記輪盤和系統選單圖示設定，改善小隊頭像更新。|Zielmarkierungsrad im Kampf und Menüoptionen; Gruppenporträts aktualisieren zuverlässiger.|Roue de marquage en combat, options du menu système et meilleure actualisation des portraits de groupe.|Rueda de marcas en combate, opciones del menú del sistema y mejor actualización de retratos de grupo.|Ruota dei contrassegni in combattimento, opzioni del menu di sistema e aggiornamento dei ritratti del gruppo migliorato.|Roda de marcas em combate, opções do menu do sistema e atualização melhorada dos retratos do grupo.|Колесо меток в бою, настройки системного меню и улучшенное обновление портретов группы.|전투 대상 징표 휠과 시스템 메뉴 아이콘 옵션을 추가하고 파티 초상화 갱신을 개선했습니다."},
{792,785,"Added a CPU profiling option; optimized aura and skill tracking during combat.|新增 CPU 性能分析开关，优化战斗中的光环及技能监控。|新增 CPU 效能分析開關，最佳化戰鬥中的光環及技能監控。|Option für CPU-Profiling; Aura- und Fähigkeitsverfolgung im Kampf optimiert.|Option de profilage CPU ; suivi des auras et techniques optimisé en combat.|Opción de perfilado de CPU y seguimiento de auras y facultades optimizado en combate.|Opzione per il profiling CPU e monitoraggio di aure e abilità ottimizzato in combattimento.|Opção de perfilamento de CPU e rastreamento de auras e habilidades otimizado em combate.|Настройка профилирования ЦП; оптимизировано отслеживание аур и способностей в бою.|CPU 프로파일링 옵션을 추가하고 전투 중 오라와 기술 추적을 최적화했습니다."},
{785,765,"Added individual mouse shortcuts and a druid mana bar in cat and bear forms; improved target refresh.|新增独立鼠标快捷功能及猎豹、熊形态法力条，优化目标刷新。|新增獨立滑鼠快捷功能及獵豹、熊形態法力條，改善目標更新。|Separate Mausaktionen und Druiden-Manaleiste in Katzen- und Bärengestalt; Zielaktualisierung verbessert.|Raccourcis souris indépendants, barre de mana du druide en félin et en ours, et meilleure actualisation de la cible.|Atajos de ratón independientes, barra de maná de druida en felino y oso, y mejor actualización del objetivo.|Scorciatoie del mouse indipendenti, barra del mana del druido in forma felina e d’orso e aggiornamento del bersaglio migliorato.|Atalhos independentes do mouse, barra de mana do druida em forma felina e de urso e atualização de alvo melhorada.|Отдельные команды мыши, полоска маны друида в облике кошки и медведя, улучшенное обновление цели.|개별 마우스 단축 동작과 표범·곰 변신 중 드루이드 마나 바를 추가하고 대상 갱신을 개선했습니다."},
{765,757,"Added party member tooltips, stance tracking and horizontal cast bar scaling.|新增队员提示、姿态监控及施法条横向缩放。|新增隊員提示、姿態監控及施法條橫向縮放。|Gruppen-Tooltips, Haltungsverfolgung und horizontale Zauberleistenskalierung.|Info-bulles des équipiers, suivi des postures et mise à l’échelle horizontale de la barre d’incantation.|Avisos de miembros del grupo, seguimiento de actitudes y escala horizontal de la barra de lanzamiento.|Descrizioni dei membri, monitoraggio delle posture e scala orizzontale della barra di lancio.|Dicas dos membros do grupo, rastreamento de posturas e escala horizontal da barra de lançamento.|Подсказки участников группы, отслеживание стоек и масштабирование полосы произнесения по ширине.|파티원 툴팁, 태세 추적 및 시전 바 가로 크기 설정을 추가했습니다."},
{757,745,"Added player buff and usable proc tracking, party buffs, and cast interruption feedback; restored combat filters for equipment monitors.|新增玩家增益、可用触发技能与队伍增益监控，加入施法中断动画，恢复装备监控的战斗筛选。|新增玩家增益、可用觸發技能與隊伍增益監控，加入施法中斷動畫，恢復裝備監控的戰鬥篩選。|Spieler- und Gruppenbuffs, auslösbare Fähigkeiten und Abbruchanimation; Kampffilter für Ausrüstung wiederhergestellt.|Suivi des améliorations du joueur et du groupe, procs utilisables et animation d’interruption ; filtres de combat rétablis pour l’équipement.|Beneficios del jugador y del grupo, activaciones utilizables y animación de interrupción; restaurados los filtros de combate del equipo.|Benefici del giocatore e del gruppo, effetti utilizzabili e animazione di interruzione; ripristinati i filtri di combattimento dell’equipaggiamento.|Bônus do jogador e grupo, efeitos utilizáveis e animação de interrupção; filtros de combate do equipamento restaurados.|Эффекты игрока и группы, доступные срабатывания и анимация прерывания; восстановлены боевые фильтры экипировки.|플레이어·파티 강화 효과와 사용 가능한 발동 추적, 시전 중단 연출을 추가하고 장비 추적 전투 필터를 복원했습니다."},
{745,731,"Improved debuff and missing-buff indicators; added cast stage sounds and standardized the blue M icon.|改进减益及缺失增益提示，新增施法分段音效并统一蓝色 M 图标。|改善減益及缺少增益提示，新增施法分段音效並統一藍色 M 圖示。|Verbesserte Debuff- und Fehlbuffanzeigen, Zauberstufentöne und einheitliches blaues M-Symbol.|Indicateurs de malus et d’améliorations manquantes affinés, sons des étapes d’incantation et icône M bleue unifiée.|Indicadores de perjuicios y beneficios ausentes mejorados, sonidos por etapa de lanzamiento e icono M azul unificado.|Indicatori di penalità e benefici mancanti migliorati, suoni delle fasi di lancio e icona M blu unificata.|Indicadores de penalidades e bônus ausentes melhorados, sons das etapas de lançamento e ícone M azul unificado.|Улучшены индикаторы отрицательных и отсутствующих эффектов; звуки стадий произнесения и единый синий значок M.|약화 효과 및 강화 효과 누락 표시를 개선하고 시전 단계 소리와 파란색 M 아이콘을 적용했습니다."},
{731,729,"Fixed protected aura button errors in Forever equipment and proc tracking.|修复无限服装备触发监控访问受保护光环按钮时报错。|修正無限服裝備觸發監控存取受保護光環按鈕時的錯誤。|Fehler mit geschützten Auraschaltflächen bei der Ausrüstungsverfolgung auf Forever korrigiert.|Correction des erreurs de boutons d’aura protégés dans le suivi d’équipement sur Forever.|Corregidos errores de botones de aura protegidos en el seguimiento de equipo en Forever.|Corretti gli errori relativi ai pulsanti aura protetti nel monitoraggio dell’equipaggiamento su Forever.|Corrigidos erros de botões de aura protegidos no rastreamento de equipamento em Forever.|Исправлены ошибки защищённых кнопок аур при отслеживании экипировки на Forever.|Forever 장비 효과 추적에서 보호된 오라 버튼 관련 오류를 수정했습니다."},
{729,720,"Added cast and attack bar stage effects, per-module undo, seven-point rogue support, and character ownership checks for monitor settings.|新增施法与攻击条分段特效、独立模块撤销、潜行者七连击点支持及监控配置角色归属校验。|新增施法與攻擊條分段特效、獨立模組復原、盜賊七連擊點支援及監控設定角色歸屬檢查。|Stufeneffekte für Zauber und Angriffe, Rückgängig je Modul, sieben Combopunkte und Charakterprüfung für Einstellungen.|Effets par étape pour incantations et attaques, annulation par module, sept points de combo et vérification du personnage des réglages.|Efectos por etapa de lanzamiento y ataque, deshacer por módulo, siete puntos de combo y verificación de ajustes por personaje.|Effetti per fasi di lancio e attacco, annullamento per modulo, sette punti combo e verifica del personaggio per le impostazioni.|Efeitos por etapa de lançamento e ataque, desfazer por módulo, sete pontos de combo e verificação do personagem nas configurações.|Эффекты стадий произнесения и атак, отмена по модулям, семь приёмов в серии и проверка владельца настроек.|시전·공격 바 단계 효과, 모듈별 실행 취소, 도적 연계 점수 7개 지원과 캐릭터별 설정 검사를 추가했습니다."},
{720,700,"Redesigned Retail class resources, added Vengeance Soul Fragments, and improved empowered casts and number formatting.|重制正式服职业资源，新增复仇灵魂残片，改进蓄力施法及数值简写。|重製正式服職業資源，新增復仇靈魂裂片，改善蓄力施法及數值簡寫。|Retail-Klassenressourcen überarbeitet, Rachsucht-Seelenfragmente ergänzt, aufgeladene Zauber und Zahlenformat verbessert.|Ressources de classe Retail revues, fragments d’âme de Vengeance ajoutés, sorts renforcés et affichage des nombres améliorés.|Renovados los recursos de clase de Retail, añadidos los fragmentos de alma de Venganza y mejorados los lanzamientos potenciados y el formato numérico.|Risorse di classe Retail rinnovate, frammenti d’anima di Vendetta aggiunti, magie potenziate e numeri migliorati.|Recursos de classe do Retail reformulados, fragmentos de alma de Vingança adicionados, conjurações potencializadas e números melhorados.|Переработаны ресурсы классов Retail, добавлены фрагменты души «Мести», улучшены усиленные заклинания и формат чисел.|본 서버 직업 자원을 개편하고 복수 영혼 파편을 추가했으며, 강화 시전과 숫자 표기를 개선했습니다."},
{700,nil,"Earliest package in the local archive.|本地归档中最早的版本。|本機封存中最早的版本。|Ältestes Paket im lokalen Archiv.|Plus ancien paquet de l’archive locale.|Paquete más antiguo del archivo local.|Pacchetto più vecchio nell’archivio locale.|Pacote mais antigo no arquivo local.|Самый ранний пакет в локальном архиве.|로컬 보관함에서 가장 오래된 패키지입니다."},
}
M.ReleaseNotes={titles=titles,locales=locales,releases=releases}

function M.ReleaseNotes.Attach(window)
    local W=M.Widgets
    local button=CreateFrame("Button",nil,window)
    button:SetSize(30,27)
    button:SetPoint("TOPRIGHT",window,"TOPRIGHT",-23,-33)
    button:SetFrameLevel(window:GetFrameLevel()+12)
    local icon=button:CreateTexture(nil,"ARTWORK")
    icon:SetPoint("CENTER")
    icon:SetSize(23,23)
    icon:SetTexture("Interface\\Icons\\INV_Scroll_03")
    local ring=button:CreateTexture(nil,"OVERLAY")
    ring:SetAllPoints()
    ring:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    ring:SetBlendMode("ADD")
    ring:SetAlpha(.35)
    local panel=W.Panel(window)
    panel:SetPoint("TOPRIGHT",button,"BOTTOMRIGHT",0,-3)
    panel:SetSize(460,385)
    panel:SetFrameLevel(window:GetFrameLevel()+25)
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
                row={version=W.Label(body,"",13),summary=W.Label(body,"",12)}
                row.version:SetTextColor(1,.82,.32)
                row.summary:SetWidth(410)
                row.summary:SetWordWrap(true)
                rows[i]=row
            end
            local version,previous,summary=unpack(release,1,3)
            local translation=1
            local first
            for entry in summary:gmatch("[^|]+") do
                first=first or entry
                if translation==index then first=entry;break end
                translation=translation+1
            end
            row.version:ClearAllPoints()
            row.version:SetPoint("TOPLEFT",2,-y)
            row.version:SetText(previous and ("v%d → v%d"):format(previous,version) or ("v%d"):format(version))
            row.summary:ClearAllPoints()
            row.summary:SetPoint("TOPLEFT",row.version,"BOTTOMLEFT",0,-4)
            row.summary:SetText(first or "")
            y=y+row.version:GetStringHeight()+row.summary:GetStringHeight()+16
        end
        body:SetHeight(math.max(1,y))
        scroll:SetVerticalScroll(0)
        language,renderedCount=index,#releases
    end
    local function Open()
        away=0
        panel:Show()
        Populate()
    end
    button:SetScript("OnEnter",function()ring:SetAlpha(.8);Open()end)
    button:SetScript("OnLeave",function()ring:SetAlpha(.35)end)
    button:SetScript("OnClick",function()
        if pinned then pinned=false;panel:Hide()
        else pinned=true;Open() end
    end)
    panel:SetScript("OnUpdate",function(self,elapsed)
        Populate()
        if pinned or MouseIsOver(button) or MouseIsOver(self) then away=0;return end
        away=away+elapsed
        if away>.35 then self:Hide() end
    end)
    window:HookScript("OnHide",function()pinned=false;panel:Hide()end)
end
