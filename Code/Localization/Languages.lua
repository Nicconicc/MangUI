local _,M=...
M.localeTables.enUS["鼠标移至屏幕顶端，显示功能菜单。"]="Move the mouse to the top of the screen to show the menu."
M.localeTables.enUS["自动（客户端）"]="Auto (client)"
M.localeTables.enUS["吸附网格线"]="Snap to grid"
M.localeTables.enUS["3D头像"]="3D portraits"
M.localeTables.enUS["目标名字"]="Target name"
M.localeTables.enUS["隐藏施法名称"]="Hide spell name"
M.localeTables.enUS["仅显示来源于自己的"]="Only show my debuffs"
M.localeTables.enUS["目标名称（姓名板）"]="Target name (nameplate)"
M.localeTables.enUS["在旋转内环上显示"]="Show on the rotating inner ring"
M.localeTables.enUS["在姓名板上显示"]="Show on the nameplate"
M.localeTables.enUS["倒计时时间"]="Countdown duration"
M.localeTables.enUS["自定义频道名"]="Custom channel name"
M.localeTables.enUS["寻求组队"]="LookingForGroup"
M.localeTables.enUS["%s：右键加入／离开频道"]="%s: right-click to join/leave the channel"
M.localeTables.enUS["开怪倒计时：左键 %d 秒，右键取消"]="Pull timer: left-click for %d seconds, right-click to cancel"
M.localeTables.enUS["点击切换聊天频道；团长/助理可发起职责确认、就位确认和倒计时。"]="Click: chat channel; leader/assist: role check, ready check, countdown."
M.localeTables.enUS["目标仇恨：T=100%，近战110%/远程130% OT，随仇恨变色。"]="Target threat: T=100%; OT: melee 110% / ranged 130%; threat color."
M.localeTables.enUS["超出设定距离：姓名板显示红叉，头像旋转内环变红。"]="Out of range: a red X appears on the nameplate; the portrait's rotating inner ring turns red."
M.localeTables.enUS["施法预览"]="Cast preview"
M.localeTables.enUS["隐藏头像"]="Hide portrait"
M.localeTables.enUS["生命进度条材质"]="Health bar texture"
M.localeTables.enUS["生命进度条颜色"]="Health bar color"
M.localeTables.enUS["生命百分比X偏移"]="Health percentage X offset"
M.localeTables.enUS["生命百分比Y偏移"]="Health percentage Y offset"
M.localeTables.enUS["施法条Y偏移"]="Cast bar Y offset"
M.localeTables.enUS["施法条颜色"]="Cast bar color"
M.localeTables.enUS["纵向间距"]="Vertical spacing"
M.localeTables.enUS["隐藏队伍编号"]="Hide party numbers"
M.localeTables.enUS["隐藏玩家自己"]="Hide self"
M.localeTables.enUS["在团队时隐藏"]="Hide in raids"
M.localeTables.enUS["玩家框体X偏移"]="Player frame X offset"
M.localeTables.enUS["生命进度条颜色/渐变开始颜色"]="Health / gradient start color"
M.localeTables.enUS["原始材质"]="Original textures"
M.localeTables.enUS["解锁移动模式"]="Unlock movement"
M.localeTables.enUS["拖动绿色区域调整位置；右键选择重叠框体。"]="Drag green areas; right-click to select overlapping frames."
-- Columns: source, German, French, Spanish, Italian, Portuguese, Russian, Korean, Traditional Chinese.
-- Regional Spanish choices remain independent saved preferences and share neutral UI wording.
local codes={"deDE","frFR","esES","itIT","ptBR","ruRU","koKR","zhTW"}
for _,code in ipairs(codes) do M.localeTables[code]={} end
local rows=[[
吸附网格线|Am Raster ausrichten|Aligner sur la grille|Ajustar a la cuadrícula|Aggancia alla griglia|Ajustar à grade|Привязка к сетке|격자에 맞추기|吸附格線
纵向间距|Vertikaler Abstand|Espacement vertical|Espaciado vertical|Spaziatura verticale|Espaçamento vertical|Вертикальный интервал|세로 간격|縱向間距
隐藏队伍编号|Gruppennummern ausblenden|Masquer les numéros|Ocultar números de grupo|Nascondi numeri gruppo|Ocultar números do grupo|Скрыть номера группы|파티 번호 숨기기|隱藏隊伍編號
隐藏玩家自己|Eigenes Fenster ausblenden|Masquer votre cadre|Ocultar tu marco|Nascondi il proprio riquadro|Ocultar seu quadro|Скрыть себя|자신 숨기기|隱藏玩家自己
在团队时隐藏|Im Schlachtzug ausblenden|Masquer en raid|Ocultar en banda|Nascondi in incursione|Ocultar em raides|Скрывать в рейде|공격대에서 숨기기|在團隊時隱藏
玩家框体X偏移|X-Versatz des Spielerfensters|Décalage X du joueur|Desplazamiento X del jugador|Spostamento X del giocatore|Deslocamento X do jogador|Смещение X рамки игрока|플레이어 프레임 X 위치|玩家框體X偏移
生命进度条颜色/渐变开始颜色|Lebensfarbe / Verlauf-Startfarbe|Couleur de vie / début du dégradé|Color de salud / inicio del degradado|Colore vita / inizio sfumatura|Cor de vida / início do gradiente|Цвет здоровья / начала градиента|생명력 / 그라데이션 시작 색상|生命進度條顏色/漸變開始顏色
原始材质|Originaltexturen|Textures originales|Texturas originales|Texture originali|Texturas originais|Исходные текстуры|기본 텍스처|原始材質
解锁移动模式|Verschieben freigeben|Déverrouiller le déplacement|Desbloquear movimiento|Sblocca spostamento|Desbloquear movimento|Разблокировать перемещение|이동 모드 잠금 해제|解鎖移動模式
拖动绿色区域调整位置；右键选择重叠框体。|Grüne Bereiche ziehen; Rechtsklick zur Auswahl überlappender Fenster.|Glissez les zones vertes ; clic droit pour choisir les cadres superposés.|Arrastra las áreas verdes; clic derecho para elegir marcos superpuestos.|Trascina le aree verdi; clic destro per scegliere riquadri sovrapposti.|Arraste as áreas verdes; clique direito para escolher quadros sobrepostos.|Перетаскивайте зелёные области; ПКМ выбирает перекрывающиеся рамки.|초록색 영역을 드래그하세요. 우클릭으로 겹친 프레임을 선택합니다.|拖動綠色區域調整位置；右鍵選擇重疊框體。
鼠标移至屏幕顶端，显示功能菜单。|Maus an den oberen Bildschirmrand bewegen, um das Menü anzuzeigen.|Placez la souris en haut de l’écran pour afficher le menu.|Mueve el ratón al borde superior para mostrar el menú.|Porta il mouse in cima allo schermo per mostrare il menu.|Mova o mouse ao topo da tela para mostrar o menu.|Наведите мышь на верхний край экрана, чтобы открыть меню.|마우스를 화면 상단으로 이동하면 메뉴가 표시됩니다.|滑鼠移至螢幕頂端，顯示功能選單。
倒计时时间|Countdown-Dauer|Durée du compte à rebours|Duración de la cuenta atrás|Durata del conto alla rovescia|Duração da contagem regressiva|Длительность отсчёта|초읽기 시간|倒計時時間
自定义频道名|Eigener Kanalname|Nom de canal personnalisé|Nombre de canal personalizado|Nome canale personalizzato|Nome de canal personalizado|Название своего канала|사용자 지정 채널 이름|自訂頻道名稱
寻求组队|LookingForGroup|LookingForGroup|LookingForGroup|LookingForGroup|LookingForGroup|LookingForGroup|파티 찾기|尋求組隊
%s：右键加入／离开频道|%s: Rechtsklick zum Beitreten/Verlassen|%s : clic droit pour rejoindre/quitter|%s: clic derecho para entrar/salir|%s: clic destro per entrare/uscire|%s: clique direito para entrar/sair|%s: ПКМ для входа/выхода|%s: 우클릭으로 채널 입장/퇴장|%s：右鍵加入／離開頻道
开怪倒计时：左键 %d 秒，右键取消|Pull-Countdown: Linksklick für %d Sekunden, Rechtsklick zum Abbrechen|Compte à rebours : clic gauche pour %d secondes, clic droit pour annuler|Cuenta atrás: clic izquierdo para %d segundos, clic derecho para cancelar|Conto alla rovescia: clic sinistro per %d secondi, destro per annullare|Contagem: clique esquerdo para %d segundos, direito para cancelar|Отсчёт: ЛКМ — %d сек., ПКМ — отмена|전투 초읽기: 좌클릭 %d초, 우클릭 취소|開怪倒計時：左鍵 %d 秒，右鍵取消
点击切换聊天频道；团长/助理可发起职责确认、就位确认和倒计时。|Klick: Chatkanal; Leiter/Assistent: Rollencheck, Bereitschaft, Countdown.|Clic : canal ; chef/assistant : rôles, appel, compte à rebours.|Clic: canal; líder/ayudante: roles, listos y cuenta atrás.|Clic: canale; capo/assistente: ruoli, pronti e conto alla rovescia.|Clique: canal; líder/assistente: funções, prontidão e contagem.|Клик: канал; лидер/помощник: роли, готовность, отсчёт.|클릭으로 채널 전환; 공대장/부공대장은 역할 확인, 준비 확인, 초읽기 가능.|點擊切換聊天頻道；團長/助理可發起職責確認、就位確認和倒計時。
目标仇恨：T=100%，近战110%/远程130% OT，随仇恨变色。|Bedrohung: T=100%; OT: Nah 110% / Fern 130%; statusabhängige Farbe.|Menace : T=100% ; OT : mêlée 110% / distance 130% ; couleur selon menace.|Amenaza: T=100%; OT: melee 110% / distancia 130%; color según amenaza.|Minaccia: T=100%; OT: mischia 110% / distanza 130%; colore per minaccia.|Ameaça: T=100%; OT: corpo a corpo 110% / distância 130%; cor por ameaça.|Угроза: T=100%; OT: вблизи 110% / вдали 130%; цвет по угрозе.|대상 위협: T=100%, 근접 110%/원거리 130% OT, 위협에 따라 색상 변경.|目標仇恨：T=100%，近戰110%/遠程130% OT，隨仇恨變色。
在旋转内环上显示|Auf dem rotierenden Innenring anzeigen|Afficher sur l’anneau intérieur rotatif|Mostrar en el anillo interior giratorio|Mostra sull’anello interno rotante|Mostrar no anel interno giratório|Показывать на вращающемся внутреннем кольце|회전하는 내부 고리에 표시|在旋轉內環上顯示
在姓名板上显示|Auf der Namensplakette anzeigen|Afficher sur la plaque de nom|Mostrar en la placa de nombre|Mostra sulla barra del nome|Mostrar na placa de nome|Показывать на индикаторе здоровья|이름표에 표시|在姓名板上顯示
超出设定距离：姓名板显示红叉，头像旋转内环变红。|Außer Reichweite: rotes X auf der Namensplakette; rotierender Porträtring wird rot.|Hors de portée : croix rouge sur la plaque de nom ; l’anneau du portrait devient rouge.|Fuera de alcance: cruz roja en la placa de nombre; el anillo del retrato se vuelve rojo.|Fuori portata: X rossa sulla barra del nome; l’anello del ritratto diventa rosso.|Fora de alcance: X vermelho na placa de nome; o anel do retrato fica vermelho.|Вне радиуса: красный крест на индикаторе здоровья; вращающееся кольцо портрета краснеет.|설정 거리 초과: 이름표에 빨간 X가 표시되고 초상화의 회전 고리가 빨갛게 변합니다.|超出設定距離：姓名板顯示紅叉，頭像旋轉內環變紅。
点击预览视窗中的元素可调节|Klicke Elemente in der Vorschau an, um sie anzupassen|Cliquez sur les éléments de l’aperçu pour les régler|Haz clic en los elementos de la vista previa para ajustarlos|Fai clic sugli elementi dell’anteprima per modificarli|Clique nos elementos da prévia para ajustá-los|Нажмите на элементы предпросмотра, чтобы настроить их|미리보기의 요소를 클릭하여 조절하세요|點擊預覽視窗中的元素可調節
隐藏头像|Porträt ausblenden|Masquer le portrait|Ocultar retrato|Nascondi ritratto|Ocultar retrato|Скрыть портрет|초상화 숨기기|隱藏頭像
生命进度条材质|Lebensleisten-Textur|Texture de la barre de vie|Textura de la barra de salud|Texture della barra della salute|Textura da barra de vida|Текстура полосы здоровья|생명력 바 텍스처|生命進度條材質
生命进度条颜色|Lebensleistenfarbe|Couleur de la barre de vie|Color de la barra de salud|Colore della barra della salute|Cor da barra de vida|Цвет полосы здоровья|생명력 바 색상|生命進度條顏色
生命百分比X偏移|Lebensprozent: X-Versatz|Décalage X du pourcentage de vie|Desplazamiento X del porcentaje de salud|Offset X della percentuale di salute|Deslocamento X da porcentagem de vida|Смещение процента здоровья по X|생명력 백분율 X 위치|生命百分比X偏移
生命百分比Y偏移|Lebensprozent: Y-Versatz|Décalage Y du pourcentage de vie|Desplazamiento Y del porcentaje de salud|Offset Y della percentuale di salute|Deslocamento Y da porcentagem de vida|Смещение процента здоровья по Y|생명력 백분율 Y 위치|生命百分比Y偏移
施法条Y偏移|Zauberleiste: Y-Versatz|Décalage Y de la barre d’incantation|Desplazamiento Y de la barra de lanzamiento|Offset Y della barra di lancio|Deslocamento Y da barra de lançamento|Смещение полосы заклинания по Y|시전 바 Y 위치|施法條Y偏移
施法条颜色|Zauberleistenfarbe|Couleur de la barre d’incantation|Color de la barra de lanzamiento|Colore della barra di lancio|Cor da barra de lançamento|Цвет полосы заклинания|시전 바 색상|施法條顏色
爱发电|Afdian|Afdian|Afdian|Afdian|Afdian|Afdian|Afdian|愛發電
更新日志|Änderungsprotokoll|Journal des modifications|Registro de cambios|Registro modifiche|Histórico de alterações|Список изменений|업데이트 내역|更新日誌
支持 MangUI 的开发。|Unterstütze die Entwicklung von MangUI.|Soutenez le développement de MangUI.|Apoya el desarrollo de MangUI.|Sostieni lo sviluppo di MangUI.|Apoie o desenvolvimento do MangUI.|Поддержите разработку MangUI.|MangUI 개발을 후원하세요.|支持 MangUI 的開發。
加入 MangUI 社区。|Tritt der MangUI-Community bei.|Rejoignez la communauté MangUI.|Únete a la comunidad de MangUI.|Unisciti alla community di MangUI.|Participe da comunidade MangUI.|Присоединяйтесь к сообществу MangUI.|MangUI 커뮤니티에 참여하세요.|加入 MangUI 社群。
查看 MangUI 的更新记录。|Lies das Änderungsprotokoll von MangUI.|Consultez les mises à jour de MangUI.|Consulta las novedades de MangUI.|Leggi le novità di MangUI.|Veja as atualizações do MangUI.|Посмотрите список изменений MangUI.|MangUI 업데이트 내역을 확인하세요.|查看 MangUI 的更新記錄。
按 Ctrl+C 复制 URL|Mit Ctrl+C die URL kopieren|Appuyez sur Ctrl+C pour copier l’URL|Pulsa Ctrl+C para copiar la URL|Premi Ctrl+C per copiare l’URL|Pressione Ctrl+C para copiar a URL|Нажмите Ctrl+C, чтобы скопировать URL|Ctrl+C를 눌러 URL을 복사하세요|按 Ctrl+C 複製 URL
显示远程攻击进度|Fortschritt von Fernkampfangriffen anzeigen|Afficher la progression des attaques à distance|Mostrar progreso del ataque a distancia|Mostra avanzamento degli attacchi a distanza|Mostrar progresso de ataques à distância|Показывать прогресс дальних атак|원거리 공격 진행 표시|顯示遠程攻擊進度
显示近战攻击进度|Fortschritt von Nahkampfangriffen anzeigen|Afficher la progression des attaques de mêlée|Mostrar progreso del ataque cuerpo a cuerpo|Mostra avanzamento degli attacchi in mischia|Mostrar progresso de ataques corpo a corpo|Показывать прогресс атак ближнего боя|근접 공격 진행 표시|顯示近戰攻擊進度
隐藏宠物能量条|Begleiterenergieleiste ausblenden|Masquer la barre d’énergie du familier|Ocultar barra de energía de mascota|Nascondi barra energia del famiglio|Ocultar barra de energia do ajudante|Скрыть полосу энергии питомца|소환수 자원 바 숨기기|隱藏寵物能量條
隐藏宠物名称|Begleiternamen ausblenden|Masquer le nom du familier|Ocultar nombre de mascota|Nascondi nome del famiglio|Ocultar nome do ajudante|Скрыть имя питомца|소환수 이름 숨기기|隱藏寵物名稱
仅显示头像和名字|Nur Porträt und Namen anzeigen|Afficher uniquement le portrait et le nom|Mostrar solo retrato y nombre|Mostra solo ritratto e nome|Mostrar apenas retrato e nome|Показывать только портрет и имя|초상화와 이름만 표시|僅顯示頭像和名字
隐藏无计时Buff|Buffs ohne Timer ausblenden|Masquer les buffs sans durée|Ocultar beneficios sin temporizador|Nascondi benefici senza durata|Ocultar buffs sem duração|Скрывать усиления без таймера|시간 제한 없는 강화 효과 숨기기|隱藏無計時Buff
低过生命阈值变色|Farbe unter Lebensschwelle ändern|Changer de couleur sous le seuil de vie|Cambiar color bajo el umbral de salud|Cambia colore sotto la soglia di salute|Mudar cor abaixo do limite de vida|Менять цвет ниже порога здоровья|생명력 기준 미만일 때 색상 변경|低過生命閾值變色
生命阈值|Lebensschwelle|Seuil de vie|Umbral de salud|Soglia di salute|Limite de vida|Порог здоровья|생명력 기준|生命閾值
低生命颜色|Farbe bei wenig Leben|Couleur de vie faible|Color de salud baja|Colore salute bassa|Cor de vida baixa|Цвет низкого здоровья|낮은 생명력 색상|低生命顏色
目标距离提示|Zielreichweitenwarnung|Alerte de portée de la cible|Aviso de distancia al objetivo|Avviso distanza bersaglio|Aviso de distância do alvo|Предупреждение о расстоянии до цели|대상 거리 경고|目標距離提示
启用渐变|Farbverlauf aktivieren|Activer le dégradé|Activar degradado|Abilita sfumatura|Ativar gradiente|Включить градиент|그라데이션 사용|啟用漸變
进度条颜色/渐变开始颜色|Leistenfarbe / Anfangsfarbe|Couleur de barre / début du dégradé|Color de barra / inicio del degradado|Colore barra / inizio sfumatura|Cor da barra / início do gradiente|Цвет полосы / начало градиента|바 색상 / 그라데이션 시작 색상|進度條顏色/漸變開始顏色
渐变结束颜色|Endfarbe des Farbverlaufs|Couleur de fin du dégradé|Color final del degradado|Colore finale della sfumatura|Cor final do gradiente|Конечный цвет градиента|그라데이션 끝 색상|漸變結束顏色
按职业显示生命条颜色|Lebensleisten in Klassenfarben anzeigen|Utiliser les couleurs de classe pour les barres de vie|Usar colores de clase en las barras de salud|Usa i colori di classe per le barre della salute|Usar cores de classe nas barras de vida|Окрашивать полосы здоровья по классу|생명력 바에 직업 색상 사용|按職業顯示生命條顏色
预览视窗中各元素可拖动|Elemente in der Vorschau können gezogen werden|Les éléments de l’aperçu peuvent être déplacés|Los elementos de la vista previa se pueden arrastrar|Gli elementi dell’anteprima possono essere trascinati|Os elementos da prévia podem ser arrastados|Элементы в окне предпросмотра можно перетаскивать|미리보기의 요소를 드래그할 수 있습니다|預覽視窗中各元素可拖動
隐藏|Ausblenden|Masquer|Ocultar|Nascondi|Ocultar|Скрыть|숨기기|隱藏
3D头像|3D-Porträts|Portraits 3D|Retratos 3D|Ritratti 3D|Retratos 3D|3D-портреты|3D 초상화|3D頭像
头像框体贴图|Porträtrahmentextur|Texture du cadre du portrait|Textura del marco del retrato|Texture della cornice del ritratto|Textura da moldura do retrato|Текстура рамки портрета|초상화 테두리 텍스처|頭像框體貼圖
稀有精英图标|Symbol seltener Elitegegner|Icône d’élite rare|Icono de élite poco común|Icona élite rara|Ícone de elite rara|Значок редкого элитного противника|희귀 정예 아이콘|稀有精英圖示
自动（客户端）|Automatisch (Client)|Automatique (client)|Automático (cliente)|Automatico (client)|Automático (cliente)|Авто (клиент)|자동 (클라이언트)|自動（客戶端）
设计|Design|Conception|Diseño|Design|Design|Дизайн|디자인|設計
其他|Sonstiges|Autres|Otros|Altro|Outros|Прочее|기타|其他
系统|System|Système|Sistema|Sistema|Sistema|Система|시스템|系統
语言版本|Sprache|Langue|Idioma|Lingua|Idioma|Язык|언어|語言版本
显示小地图图标|Minikartensymbol anzeigen|Afficher l’icône de la minicarte|Mostrar icono del minimapa|Mostra icona sulla minimappa|Mostrar ícone no minimapa|Показывать значок у мини-карты|미니맵 아이콘 표시|顯示小地圖圖示
显示|Anzeige|Affichage|Visualización|Visualizzazione|Exibição|Отображение|표시|顯示
宠物名称|Begleitername|Nom du familier|Nombre de mascota|Nome del famiglio|Nome do ajudante|Имя питомца|소환수 이름|寵物名稱
无目标时隐藏框体|Fenster ohne Ziel ausblenden|Masquer les cadres sans cible|Ocultar marcos sin objetivo|Nascondi riquadri senza bersaglio|Ocultar quadros sem alvo|Скрывать рамки без цели|대상이 없으면 프레임 숨기기|無目標時隱藏框體
配置分享|Konfiguration teilen|Partage de configuration|Compartir configuración|Condividi configurazione|Compartilhar configuração|Обмен настройками|설정 공유|設定分享
导出配置|Konfiguration exportieren|Exporter la configuration|Exportar configuración|Esporta configurazione|Exportar configuração|Экспорт настроек|설정 내보내기|匯出設定
导入配置|Konfiguration importieren|Importer la configuration|Importar configuración|Importa configurazione|Importar configuração|Импорт настроек|설정 가져오기|匯入設定
确认导入|Importieren|Importer|Importar|Importa|Importar|Импортировать|가져오기|確認匯入
全选|Alles auswählen|Tout sélectionner|Seleccionar todo|Seleziona tutto|Selecionar tudo|Выбрать всё|전체 선택|全選
配置导入成功。|Konfiguration importiert.|Configuration importée.|Configuración importada.|Configurazione importata.|Configuração importada.|Настройки импортированы.|설정을 가져왔습니다.|設定匯入成功。
玩家与目标主框体|Spieler- und Zielfenster|Cadres du joueur et de la cible|Marcos de jugador y objetivo|Riquadri giocatore e bersaglio|Quadros do jogador e do alvo|Рамки игрока и цели|플레이어 및 대상 프레임|玩家與目標主框體
玩家施法条|Spielerzauberleiste|Barre d’incantation du joueur|Barra de lanzamiento del jugador|Barra di lancio del giocatore|Barra de lançamento do jogador|Полоса заклинаний игрока|플레이어 시전바|玩家施法條
宠物框体|Begleiterfenster|Cadre du familier|Marco de mascota|Riquadro famiglio|Quadro do ajudante|Рамка питомца|소환수 프레임|寵物框體
目标的目标框体|Ziel-des-Ziels-Fenster|Cadre de la cible de la cible|Marco del objetivo del objetivo|Riquadro bersaglio del bersaglio|Quadro do alvo do alvo|Рамка цели цели|대상의 대상 프레임|目標的目標框體
队伍框体|Gruppenfenster|Cadres de groupe|Marcos de grupo|Riquadri gruppo|Quadros de grupo|Рамки группы|파티 프레임|隊伍框體
焦点框体|Fokusfenster|Cadre de focalisation|Marco de foco|Riquadro focus|Quadro de foco|Рамка фокуса|주시 대상 프레임|焦點框體
技能冷却监控|Abklingzeitüberwachung|Suivi des temps de recharge|Seguimiento de reutilización|Monitoraggio recuperi|Monitoramento de recargas|Отслеживание перезарядок|재사용 대기시간 추적|技能冷卻監控
聊天与功能按钮|Chat- und Funktionsschaltflächen|Boutons de discussion et utilitaires|Botones de chat y utilidades|Pulsanti chat e funzioni|Botões de bate-papo e funções|Кнопки чата и функций|채팅 및 기능 버튼|聊天與功能按鈕
系统菜单|Systemmenü|Menu système|Menú del sistema|Menu di sistema|Menu do sistema|Системное меню|시스템 메뉴|系統選單
经验条|Erfahrungsleiste|Barre d’expérience|Barra de experiencia|Barra dell’esperienza|Barra de experiência|Полоса опыта|경험치 바|經驗條
鼠标光圈提示|Mauszeigerring|Anneau du curseur|Anillo del cursor|Anello del cursore|Anel do cursor|Кольцо курсора|마우스 원형 표시|滑鼠光圈提示
目标仇恨|Zielbedrohung|Menace sur la cible|Amenaza del objetivo|Minaccia sul bersaglio|Ameaça no alvo|Угроза для цели|대상 위협 수준|目標仇恨
目标距离|Zielentfernung|Distance de la cible|Distancia del objetivo|Distanza dal bersaglio|Distância do alvo|Расстояние до цели|대상 거리|目標距離
目标距离监控|Zielreichweitenüberwachung|Suivi de la portée de la cible|Monitor de distancia del objetivo|Monitor della distanza del bersaglio|Monitor de distância do alvo|Монитор расстояния до цели|대상 거리 모니터링|目標距離監控
目标仇恨监控|Zielbedrohungsüberwachung|Suivi de la menace sur la cible|Monitor de amenaza del objetivo|Monitor della minaccia sul bersaglio|Monitor de ameaça do alvo|Монитор угрозы цели|대상 위협 모니터링|目標仇恨監控
进入和离开战斗提示|Kampf-Eintritts- und Austrittsmeldungen|Alertes d’entrée et de sortie de combat|Avisos de entrada y salida de combate|Avvisi di inizio e fine combattimento|Avisos de entrada e saída de combate|Оповещения о начале и конце боя|전투 시작 및 종료 알림|進入和離開戰鬥提示
启动模块|Modul aktivieren|Activer le module|Activar módulo|Abilita modulo|Ativar módulo|Включить модуль|모듈 활성화|啟用模組
恢复默认|Standard wiederherstellen|Rétablir les valeurs par défaut|Restaurar valores predeterminados|Ripristina valori predefiniti|Restaurar padrões|По умолчанию|기본값 복원|恢復預設
移动框体|Fenster verschieben|Déplacer le cadre|Mover marco|Sposta riquadro|Mover quadro|Переместить рамку|프레임 이동|移動框體
完成移动|Verschieben beenden|Terminer le déplacement|Terminar movimiento|Termina spostamento|Concluir movimento|Завершить перемещение|이동 완료|完成移動
关闭|Schließen|Fermer|Cerrar|Chiudi|Fechar|Закрыть|닫기|關閉
确定|OK|OK|Aceptar|OK|OK|ОК|확인|確定
取消|Abbrechen|Annuler|Cancelar|Annulla|Cancelar|Отмена|취소|取消
默认|Standard|Par défaut|Predeterminado|Predefinito|Padrão|По умолчанию|기본값|預設
整体缩放|Gesamtskalierung|Échelle globale|Escala general|Scala generale|Escala geral|Общий масштаб|전체 크기|整體縮放
缩放|Skalierung|Échelle|Escala|Scala|Escala|Масштаб|크기|縮放
图标大小|Symbolgröße|Taille des icônes|Tamaño de icono|Dimensione icona|Tamanho do ícone|Размер значка|아이콘 크기|圖示大小
X偏移|X-Versatz|Décalage X|Desplazamiento X|Scostamento X|Deslocamento X|Смещение X|X 위치 보정|X偏移
Y偏移|Y-Versatz|Décalage Y|Desplazamiento Y|Scostamento Y|Deslocamento Y|Смещение Y|Y 위치 보정|Y偏移
判定距离设置|Entfernungsschwellen|Seuils de distance|Umbrales de distancia|Soglie di distanza|Limites de distância|Пороги расстояния|거리 기준 설정|判定距離設定
战士|Krieger|Guerrier|Guerrero|Guerriero|Guerreiro|Воин|전사|戰士
圣骑士|Paladin|Paladin|Paladín|Paladino|Paladino|Паладин|성기사|聖騎士
猎人|Jäger|Chasseur|Cazador|Cacciatore|Caçador|Охотник|사냥꾼|獵人
潜行者|Schurke|Voleur|Pícaro|Ladro|Ladino|Разбойник|도적|盜賊
牧师|Priester|Prêtre|Sacerdote|Sacerdote|Sacerdote|Жрец|사제|牧師
死亡骑士|Todesritter|Chevalier de la mort|Caballero de la Muerte|Cavaliere della Morte|Cavaleiro da Morte|Рыцарь смерти|죽음의 기사|死亡騎士
萨满祭司|Schamane|Chaman|Chamán|Sciamano|Xamã|Шаман|주술사|薩滿
法师|Magier|Mage|Mago|Mago|Mago|Маг|마법사|法師
术士|Hexenmeister|Démoniste|Brujo|Stregone|Bruxo|Чернокнижник|흑마법사|術士
德鲁伊|Druide|Druide|Druida|Druido|Druida|Друид|드루이드|德魯伊
字体|Schriftart|Police|Fuente|Carattere|Fonte|Шрифт|글꼴|字型
字体大小|Schriftgröße|Taille de police|Tamaño de fuente|Dimensione carattere|Tamanho da fonte|Размер шрифта|글꼴 크기|字型大小
字体Y偏移|Schrift-Y-Versatz|Décalage Y du texte|Desplazamiento Y del texto|Scostamento Y del testo|Deslocamento Y do texto|Смещение текста по Y|글꼴 Y 위치 보정|字型Y偏移
按钮间隔|Schaltflächenabstand|Espacement des boutons|Separación de botones|Spaziatura pulsanti|Espaçamento dos botões|Интервал кнопок|버튼 간격|按鈕間隔
元素间隔|Elementabstand|Espacement des éléments|Separación de elementos|Spaziatura elementi|Espaçamento dos elementos|Интервал элементов|요소 간격|元素間隔
经验条高度|Höhe der Erfahrungsleiste|Hauteur de la barre d’expérience|Altura de la barra de experiencia|Altezza barra esperienza|Altura da barra de experiência|Высота полосы опыта|경험치 바 높이|經驗條高度
外圈颜色|Farbe des äußeren Rings|Couleur de l’anneau extérieur|Color del anillo exterior|Colore anello esterno|Cor do anel externo|Цвет внешнего кольца|바깥 원 색상|外圈顏色
内圈颜色|Farbe des inneren Rings|Couleur de l’anneau intérieur|Color del anillo interior|Colore anello interno|Cor do anel interno|Цвет внутреннего кольца|안쪽 원 색상|內圈顏色
GCD圈颜色|Farbe des GCD-Rings|Couleur de l’anneau GCD|Color del anillo GCD|Colore anello GCD|Cor do anel GCD|Цвет кольца ГКД|글로벌 재사용 대기시간 원 색상|GCD圈顏色
音效|Ton|Son|Sonido|Suono|Som|Звук|소리|音效
黑名单|Sperrliste|Liste noire|Lista negra|Lista esclusioni|Lista de bloqueio|Чёрный список|제외 목록|黑名單
最小冷却时间监控|Minimale überwachte Abklingzeit|Temps de recharge minimal suivi|Reutilización mínima supervisada|Recupero minimo monitorato|Recarga mínima monitorada|Минимальная отслеживаемая перезарядка|추적할 최소 재사용 대기시간|最小冷卻時間監控
最大冷却时间监控|Maximale überwachte Abklingzeit|Temps de recharge maximal suivi|Reutilización máxima supervisada|Recupero massimo monitorato|Recarga máxima monitorada|Максимальная отслеживаемая перезарядка|추적할 최대 재사용 대기시간|最大冷卻時間監控
黑名单为空|Die Sperrliste ist leer|La liste noire est vide|La lista negra está vacía|La lista esclusioni è vuota|A lista de bloqueio está vazia|Чёрный список пуст|제외 목록이 비어 있습니다|黑名單為空
添加黑名单|Zur Sperrliste hinzufügen|Ajouter à la liste noire|Añadir a la lista negra|Aggiungi alle esclusioni|Adicionar à lista de bloqueio|Добавить в чёрный список|제외 목록에 추가|加入黑名單
移除黑名单|Aus Sperrliste entfernen|Retirer de la liste noire|Quitar de la lista negra|Rimuovi dalle esclusioni|Remover da lista de bloqueio|Удалить из чёрного списка|제외 목록에서 제거|移出黑名單
清除所有|Alles löschen|Tout effacer|Borrar todo|Cancella tutto|Limpar tudo|Очистить всё|모두 지우기|全部清除
名称|Name|Nom|Nombre|Nome|Nome|Название|이름|名稱
宽度|Breite|Largeur|Anchura|Larghezza|Largura|Ширина|너비|寬度
高度|Höhe|Hauteur|Altura|Altezza|Altura|Высота|높이|高度
透明度|Deckkraft|Opacité|Opacidad|Opacità|Opacidade|Непрозрачность|불투명도|透明度
图层|Ebene|Couche|Capa|Livello|Camada|Слой|레이어|圖層
显示元素|Element anzeigen|Afficher l’élément|Mostrar elemento|Mostra elemento|Mostrar elemento|Показывать элемент|요소 표시|顯示元素
锁定位置|Position sperren|Verrouiller la position|Bloquear posición|Blocca posizione|Bloquear posição|Закрепить положение|위치 잠금|鎖定位置
进度条材质|Leistentextur|Texture de barre|Textura de barra|Texture della barra|Textura da barra|Текстура полосы|진행바 텍스처|進度條材質
施法图标大小|Zaubersymbolgröße|Taille de l’icône du sort|Tamaño del icono de hechizo|Dimensione icona incantesimo|Tamanho do ícone de feitiço|Размер значка заклинания|시전 아이콘 크기|施法圖示大小
玩家生命条|Spieler-Lebensleiste|Barre de vie du joueur|Barra de salud del jugador|Barra salute giocatore|Barra de vida do jogador|Полоса здоровья игрока|플레이어 생명력 바|玩家生命條
玩家能量条|Spieler-Ressourcenleiste|Barre de ressource du joueur|Barra de recurso del jugador|Barra risorsa giocatore|Barra de recurso do jogador|Полоса ресурса игрока|플레이어 자원 바|玩家能量條
玩家生命值|Spielerleben|Vie du joueur|Salud del jugador|Salute giocatore|Vida do jogador|Здоровье игрока|플레이어 생명력|玩家生命值
玩家能量值|Spielerressource|Ressource du joueur|Recurso del jugador|Risorsa giocatore|Recurso do jogador|Ресурс игрока|플레이어 자원|玩家能量值
目标生命条|Ziel-Lebensleiste|Barre de vie de la cible|Barra de salud del objetivo|Barra salute bersaglio|Barra de vida do alvo|Полоса здоровья цели|대상 생명력 바|目標生命條
目标能量条|Ziel-Ressourcenleiste|Barre de ressource de la cible|Barra de recurso del objetivo|Barra risorsa bersaglio|Barra de recurso do alvo|Полоса ресурса цели|대상 자원 바|目標能量條
目标生命值|Zielleben|Vie de la cible|Salud del objetivo|Salute bersaglio|Vida do alvo|Здоровье цели|대상 생명력|目標生命值
目标生命值百分比|Zielleben in Prozent|Pourcentage de vie de la cible|Porcentaje de salud del objetivo|Percentuale salute bersaglio|Porcentagem de vida do alvo|Процент здоровья цели|대상 생명력 백분율|目標生命值百分比
目标能量值|Zielressource|Ressource de la cible|Recurso del objetivo|Risorsa bersaglio|Recurso do alvo|Ресурс цели|대상 자원|目標能量值
目标Buff|Zielstärkungen|Améliorations de la cible|Beneficios del objetivo|Benefici bersaglio|Benefícios do alvo|Положительные эффекты цели|대상 강화 효과|目標增益
目标Debuff|Zielschwächungen|Affaiblissements de la cible|Perjuicios del objetivo|Malefici bersaglio|Penalidades do alvo|Отрицательные эффекты цели|대상 약화 효과|目標減益
头像框体|Porträtfenster|Cadre du portrait|Marco del retrato|Riquadro ritratto|Quadro do retrato|Рамка портрета|초상화 프레임|頭像框體
目标姓名|Zielname|Nom de la cible|Nombre del objetivo|Nome bersaglio|Nome do alvo|Имя цели|대상 이름|目標姓名
目标团队标记|Ziel-Schlachtzugsmarkierung|Marqueur de raid de la cible|Marca de banda del objetivo|Marcatore incursione bersaglio|Marcador de raide do alvo|Метка рейда на цели|대상 공격대 징표|目標團隊標記
头像等级|Porträtstufe|Niveau du portrait|Nivel del retrato|Livello ritratto|Nível do retrato|Уровень на портрете|초상화 레벨|頭像等級
目标精英与稀有图标|Elite- und Seltenheitssymbole des Ziels|Icônes élite et rare de la cible|Iconos de élite y raro del objetivo|Icone élite e raro bersaglio|Ícones de elite e raro do alvo|Значки элиты и редкости цели|대상 정예 및 희귀 아이콘|目標精英與稀有圖示
头像框体装饰|Porträtdekoration|Décoration du portrait|Decoración del retrato|Decorazione ritratto|Decoração do retrato|Украшение портрета|초상화 장식|頭像框體裝飾
动画特效|Animationseffekte|Effets d’animation|Efectos de animación|Effetti animati|Efeitos de animação|Эффекты анимации|애니메이션 효과|動畫特效
玩家资源|Spielerressourcen|Ressources du joueur|Recursos del jugador|Risorse giocatore|Recursos do jogador|Ресурсы игрока|플레이어 자원|玩家資源
目标施法条|Zielzauberleiste|Barre d’incantation de la cible|Barra de lanzamiento del objetivo|Barra di lancio del bersaglio|Barra de lançamento do alvo|Полоса заклинаний цели|대상 시전바|目標施法條
隐藏施法名称|Zaubernamen ausblenden|Masquer le nom du sort|Ocultar el nombre del hechizo|Nascondi il nome dell'incantesimo|Ocultar nome da magia|Скрыть название заклинания|주문 이름 숨기기|隱藏施法名稱
仅显示来源于自己的|Nur eigene Schwächungen anzeigen|Afficher uniquement mes affaiblissements|Mostrar solo mis perjuicios|Mostra solo i miei effetti negativi|Mostrar apenas minhas penalidades|Показывать только мои отрицательные эффекты|내 약화 효과만 표시|僅顯示來源於自己的
头像缩放|Porträtskalierung|Échelle du portrait|Escala del retrato|Scala ritratto|Escala do retrato|Масштаб портрета|초상화 크기|頭像縮放
头像 X 位置|Porträt-X|Position X du portrait|Posición X del retrato|Posizione X ritratto|Posição X do retrato|Портрет по X|초상화 X 위치|頭像 X 位置
血量条 Y|Lebensleiste-Y|Position Y de la barre de vie|Posición Y de la barra de salud|Posizione Y barra salute|Posição Y da barra de vida|Полоса здоровья по Y|생명력 바 Y 위치|血量條 Y
最多显示Buff数|Maximale Stärkungen|Nombre maximal d’améliorations|Máximo de beneficios|Benefici massimi|Máximo de benefícios|Максимум положительных эффектов|최대 강화 효과 수|最多顯示增益數
每行显示Buff数|Stärkungen pro Zeile|Améliorations par ligne|Beneficios por fila|Benefici per riga|Benefícios por linha|Положительных эффектов в ряду|행당 강화 효과 수|每行顯示增益數
最多显示Debuff数|Maximale Schwächungen|Nombre maximal d’affaiblissements|Máximo de perjuicios|Malefici massimi|Máximo de penalidades|Максимум отрицательных эффектов|최대 약화 효과 수|最多顯示減益數
每行显示Debuff数|Schwächungen pro Zeile|Affaiblissements par ligne|Perjuicios por fila|Malefici per riga|Penalidades por linha|Отрицательных эффектов в ряду|행당 약화 효과 수|每行顯示減益數
属性|Eigenschaften|Propriétés|Propiedades|Proprietà|Propriedades|Свойства|속성|屬性
分组|Gruppe|Groupe|Grupo|Gruppo|Grupo|Группа|그룹|分組
玩家|Spieler|Joueur|Jugador|Giocatore|Jogador|Игрок|플레이어|玩家
目标|Ziel|Cible|Objetivo|Bersaglio|Alvo|Цель|대상|目標
宠物|Begleiter|Familier|Mascota|Famiglio|Ajudante|Питомец|소환수|寵物
焦点|Fokus|Focalisation|Foco|Focus|Foco|Фокус|주시 대상|焦點
等级|Stufe|Niveau|Nivel|Livello|Nível|Уровень|레벨|等級
目标名字|Zielname|Nom de la cible|Nombre del objetivo|Nome del bersaglio|Nome do alvo|Имя цели|대상 이름|目標名稱
目标名称（姓名板）|Zielname (Namensplakette)|Nom de la cible (plaque de nom)|Nombre del objetivo (placa de nombre)|Nome del bersaglio (barra del nome)|Nome do alvo (placa de nome)|Имя цели (индикатор здоровья)|대상 이름 (이름표)|目標名稱（姓名板）
施法预览|Zaubervorschau|Aperçu d’incantation|Vista previa de lanzamiento|Anteprima lancio|Prévia de lançamento|Предпросмотр заклинания|시전 미리보기|施法預覽
冷却预览|Abklingzeitvorschau|Aperçu de recharge|Vista previa de reutilización|Anteprima recupero|Prévia de recarga|Предпросмотр перезарядки|재사용 대기시간 미리보기|冷卻預覽
法术书|Zauberbuch|Grimoire|Libro de hechizos|Libro degli incantesimi|Grimório|Книга заклинаний|주문책|法術書
天赋|Talente|Talents|Talentos|Talenti|Talentos|Таланты|특성|天賦
成就|Erfolge|Hauts faits|Logros|Imprese|Conquistas|Достижения|업적|成就
藏品|Sammlungen|Collections|Colecciones|Collezioni|Coleções|Коллекции|수집품|收藏
地下城查找器|Dungeonbrowser|Outil Donjons|Buscador de mazmorras|Ricerca spedizioni|Localizador de masmorras|Поиск подземелий|던전 찾기|地城搜尋器
说话|Sagen|Dire|Decir|Dici|Dizer|Сказать|일반 대화|說話
大喊|Schreien|Crier|Gritar|Urla|Gritar|Крикнуть|외치기|大喊
公会|Gilde|Guilde|Hermandad|Gilda|Guilda|Гильдия|길드|公會
队伍|Gruppe|Groupe|Grupo|Gruppo|Grupo|Группа|파티|隊伍
团队|Schlachtzug|Raid|Banda|Incursione|Raide|Рейд|공격대|團隊
战场|Schlachtfeld|Champ de bataille|Campo de batalla|Campo di battaglia|Campo de batalha|Поле боя|전장|戰場
副本|Instanz|Instance|Instancia|Istanza|Instância|Подземелье|인스턴스|副本
职责确认|Rollenabfrage|Vérification des rôles|Comprobación de funciones|Controllo ruoli|Verificação de função|Проверка ролей|역할 확인|職責確認
就位确认|Bereitschaftsabfrage|Appel|Comprobación de listos|Controllo pronti|Verificação de prontidão|Проверка готовности|준비 확인|就位確認
正在施法|Zauber wird gewirkt|Incantation en cours|Lanzando|Lancio in corso|Lançando|Применение заклинания|시전 중|正在施法
死亡|Tot|Mort|Muerto|Morto|Morto|Мёртв|죽음|死亡
暂离|AFK|Absent|Ausente|Assente|Ausente|Нет на месте|자리 비움|暫離
]]
for line in rows:gmatch("[^\r\n]+") do
    local fields={};for field in line:gmatch("[^|]+") do fields[#fields+1]=field end
    for index,code in ipairs(codes) do M.localeTables[code][fields[1]]=fields[index+1] end
end
M.localeTables.esMX=M.Copy and M.Copy(M.localeTables.esES) or {}
if not M.Copy then for key,value in pairs(M.localeTables.esES) do M.localeTables.esMX[key]=value end end

-- Keep existing translations available after the designer's label cleanup.
local designerLabels={
    ["头像X偏移"]={"头像 X 位置","Portrait X offset"},
    ["宠物头像X偏移"]={"宠物头像X偏移","Pet portrait X offset"},
    ["焦点头像X偏移"]={"头像 X 位置","Focus portrait X offset"},
    ["目标的目标头像X偏移"]={"头像 X 位置","Target-of-target portrait X offset"},
    ["宠物名称X偏移"]={"宠物名字 X","Pet name X offset"},
    ["宠物名称Y偏移"]={"宠物名字 Y","Pet name Y offset"},
    ["焦点名称X偏移"]={"焦点名字 X","Focus name X offset"},
    ["焦点名称Y偏移"]={"焦点名字 Y","Focus name Y offset"},
    ["目标的目标名称X偏移"]={"目标的目标名字 X","Target-of-target name X offset"},
    ["目标的目标名称Y偏移"]={"目标的目标名字 Y","Target-of-target name Y offset"},
    ["生命条Y偏移"]={"血量条 Y","Health bar Y offset"},
    ["施法条X偏移"]={"施法条 X","Cast bar X offset"},
    ["施法条Y偏移"]={"施法条 Y","Cast bar Y offset"},
    ["仅显示头像和名称"]={"仅显示头像和名字","Show only portrait and name"},
    ["单位名称"]={"单位名字","Unit name"},
    ["队员纵向间距"]={"纵向间距","Member vertical spacing"},
    ["文字Y偏移"]={"字体Y偏移","Text Y offset"},
    ["按钮间距"]={"按钮间隔","Button spacing"},
    ["元素间距"]={"元素间隔","Element spacing"},
    ["最短冷却时间（秒）"]={"最小冷却时间监控","Minimum cooldown (seconds)"},
    ["最长冷却时间（秒）"]={"最大冷却时间监控","Maximum cooldown (seconds)"},
    ["倒计时时间（秒）"]={"倒计时时间","Pull countdown (seconds)"},
    ["播放音效"]={"音效","Play sound"},
    ["不监控的技能／物品"]={"黑名单","Excluded spells / items"},
    ["低生命值变色"]={"低过生命阈值变色","Change color at low health"},
    ["生命值阈值"]={"生命阈值","Health threshold"},
    ["手动距离（码）"]={"手动设置距离","Manual range (yards)"},
    ["减益图标数量上限"]={"最多显示Debuff数","Maximum debuff icons"},
    ["每行减益图标数量"]={"每行显示Debuff数","Debuff icons per row"},
    ["增益图标数量上限"]={"最多显示Buff数","Maximum buff icons"},
    ["每行增益图标数量"]={"每行显示Buff数","Buff icons per row"},
    ["隐藏无持续时间的增益"]={"隐藏无计时Buff","Hide buffs without a duration"},
    ["玻璃透明度"]={"玻璃贴图透明度","Glass opacity"},
    ["模型X偏移"]={"模型 X","Model X offset"},
    ["模型Y偏移"]={"模型 Y","Model Y offset"},
    ["模型Z偏移"]={"模型 Z","Model Z offset"},
    ["生命与能量条材质"]={nil,"Health and power bar texture"},
    ["名称字体大小"]={nil,"Name font size"},
    ["姓名板标记大小"]={nil,"Nameplate marker size"},
    ["姓名板标记X偏移"]={nil,"Nameplate marker X offset"},
    ["姓名板标记Y偏移"]={nil,"Nameplate marker Y offset"},
    ["按职业填写技能名称或ID，以技能射程判断距离；勾选手动距离后使用设定码数。无法判定时不提示。"]={nil,"Enter a spell name or ID for each class to use its range. Enable manual range to use the chosen yard distance. Unknown ranges do not trigger a warning."},
}
for key,entry in pairs(designerLabels)do
    for code,catalog in pairs(M.localeTables)do
        if code~="enUS"then catalog[key]=(entry[1]and catalog[entry[1]])or entry[2]end
    end
    M.localeTables.enUS[key]=entry[2]
end
