local _,M=...
-- Reviewed against the Simplified Chinese UI. Columns: source, en, de, fr, es, it, pt, ru, ko, zhTW.
local codes={"enUS","deDE","frFR","esES","itIT","ptBR","ruRU","koKR","zhTW"}
local rows=[[
玩家生命值百分比|Player health percentage|Spielerleben in Prozent|Pourcentage de vie du joueur|Porcentaje de salud del jugador|Percentuale salute giocatore|Porcentagem de vida do jogador|Процент здоровья игрока|플레이어 생명력 백분율|玩家生命值百分比
仅在副本中显示|Only show in dungeons and raids|Nur in Dungeons und Schlachtzügen anzeigen|Afficher uniquement en donjons et raids|Mostrar solo en mazmorras y bandas|Mostra solo in spedizioni e incursioni|Mostrar apenas em masmorras e raides|Показывать только в подземельях и рейдах|던전과 공격대에서만 표시|僅在副本中顯示
世界|World|Welt|Monde|Mundo|Mondo|Mundo|Мир|세계|世界
文本显示|Text labels|Textbeschriftungen|Libellés textuels|Etiquetas de texto|Etichette di testo|Rótulos de texto|Текстовые подписи|텍스트 표시|文字顯示
说|Say|Sagen|Dire|Decir|Parla|Dizer|Сказать|일반|說
大喊|Yell|Schreien|Crier|Gritar|Urla|Gritar|Крикнуть|외침|大喊
公会|Guild|Gilde|Guilde|Hermandad|Gilda|Guilda|Гильдия|길드|公會
队伍|Party|Gruppe|Groupe|Grupo|Gruppo|Grupo|Группа|파티|隊伍
团队|Raid|Schlachtzug|Raid|Banda|Incursione|Raide|Рейд|공격대|團隊
战场|Battleground|Schlachtfeld|Champ de bataille|Campo de batalla|Campo di battaglia|Campo de batalha|Поле боя|전장|戰場
副本|Instance|Instanz|Instance|Instancia|Istanza|Instância|Подземелье|인스턴스|副本
寻求组队|Looking for Group|Gruppensuche|Recherche de groupe|Buscar grupo|Ricerca gruppo|Procurando grupo|Поиск группы|파티 찾기|尋求組隊
骰子|Roll|Würfeln|Jet de dés|Tirar|Tiro di dadi|Rolar dados|Бросок|주사위|骰子
职责|Role|Rolle|Rôle|Rol|Ruolo|Função|Роль|역할|職責
就位|Ready|Bereit|Prêt|Listo|Pronto|Pronto|Готовность|준비|就位
倒计时|Countdown|Countdown|Compte à rebours|Cuenta atrás|Conto alla rovescia|Contagem regressiva|Отсчёт|초읽기|倒數計時
使用全局字体|Use global font|Globale Schrift verwenden|Utiliser la police globale|Usar fuente global|Usa carattere globale|Usar fonte global|Использовать общий шрифт|공통 글꼴 사용|使用全域字型
大小|Size|Größe|Taille|Tamaño|Dimensione|Tamanho|Размер|크기|大小
撤销|Undo|Rückgängig|Annuler|Deshacer|Annulla|Desfazer|Отменить|실행 취소|復原
最多保留10次调节；切换元素或tab后清空。|Undo up to 10 changes. Selecting another element or tab clears the history.|Bis zu 10 Änderungen rückgängig machen. Ein anderes Element oder Register löscht den Verlauf.|Annulez jusqu’à 10 modifications. Changer d’élément ou d’onglet efface l’historique.|Deshaz hasta 10 cambios. Cambiar de elemento o pestaña borra el historial.|Annulla fino a 10 modifiche. Cambiare elemento o scheda cancella la cronologia.|Desfaça até 10 alterações. Trocar de elemento ou aba limpa o histórico.|Можно отменить до 10 изменений. Выбор другого элемента или вкладки очищает историю.|최대 10회까지 실행 취소합니다. 다른 요소나 탭을 선택하면 기록이 지워집니다.|最多可復原10次調整；選擇其他元素或頁籤後清空紀錄。
MangUI卡牌大师|MangUI Card Master|MangUI Card Master|MangUI Card Master|MangUI Card Master|MangUI Card Master|MangUI Card Master|MangUI Card Master|MangUI Card Master|MangUI卡牌大師
与插件“MangUI卡牌大师”配合使用体验更佳|For the best experience, use with “MangUI Card Master”.|Für ein besseres Erlebnis zusammen mit „MangUI Card Master“ verwenden.|Pour une meilleure expérience, utilisez aussi « MangUI Card Master ».|Para una mejor experiencia, úsalo con «MangUI Card Master».|Per un’esperienza migliore, usa anche «MangUI Card Master».|Para uma experiência melhor, use com “MangUI Card Master”.|Для лучшего результата используйте вместе с «MangUI Card Master».|“MangUI Card Master” 애드온과 함께 사용하면 더욱 좋습니다.|搭配「MangUI卡牌大師」插件使用，體驗更佳。
复制插件名在任意插件平台搜索。|Copy the addon name and search for it on any addon platform.|Addonnamen kopieren und auf einer Addon-Plattform suchen.|Copiez le nom de l’addon et recherchez-le sur une plateforme d’addons.|Copia el nombre del addon y búscalo en cualquier plataforma de addons.|Copia il nome dell’addon e cercalo su una piattaforma di addon.|Copie o nome do addon e pesquise em qualquer plataforma de addons.|Скопируйте название аддона и найдите его на любой платформе аддонов.|애드온 이름을 복사하여 애드온 플랫폼에서 검색하세요.|複製插件名稱，在任意插件平台搜尋。
按 Ctrl+C 复制插件名|Press Ctrl+C to copy the addon name|Mit Ctrl+C den Addonnamen kopieren|Ctrl+C pour copier le nom de l’addon|Pulsa Ctrl+C para copiar el nombre del addon|Premi Ctrl+C per copiare il nome dell’addon|Pressione Ctrl+C para copiar o nome do addon|Нажмите Ctrl+C, чтобы скопировать название аддона|Ctrl+C를 눌러 애드온 이름을 복사하세요|按 Ctrl+C 複製插件名稱
名称X偏移|Name X offset|Name – X-Versatz|Nom : décalage X|Nombre: desplazamiento X|Nome: scostamento X|Nome: deslocamento X|Имя: смещение X|이름 X 위치 조정|名稱X偏移
名称Y偏移|Name Y offset|Name – Y-Versatz|Nom : décalage Y|Nombre: desplazamiento Y|Nome: scostamento Y|Nome: deslocamento Y|Имя: смещение Y|이름 Y 위치 조정|名稱Y偏移
名称字体大小|Name font size|Schriftgröße des Namens|Taille du nom|Tamaño de fuente del nombre|Dimensione del nome|Tamanho da fonte do nome|Размер шрифта имени|이름 글꼴 크기|名稱字型大小
生命与能量条材质|Health and power bar texture|Textur für Leben und Ressourcen|Texture des barres de vie et de ressource|Textura de salud y recursos|Texture di salute e risorse|Textura de vida e recursos|Текстура полос здоровья и ресурсов|생명력 및 자원 바 텍스처|生命與能量條材質
姓名板标记大小|Nameplate marker size|Markierung auf Namensplakette – Größe|Taille du marqueur de plaque de nom|Tamaño del marcador de placa|Dimensione indicatore barra del nome|Tamanho do marcador na placa de nome|Размер метки на индикаторе здоровья|이름표 표시 크기|名條標記大小
姓名板标记X偏移|Nameplate marker X offset|Markierung auf Namensplakette – X|Marqueur de plaque : décalage X|Marcador de placa: desplazamiento X|Indicatore nome: scostamento X|Marcador da placa: deslocamento X|Метка индикатора: смещение X|이름표 표시 X 위치 조정|名條標記X偏移
姓名板标记Y偏移|Nameplate marker Y offset|Markierung auf Namensplakette – Y|Marqueur de plaque : décalage Y|Marcador de placa: desplazamiento Y|Indicatore nome: scostamento Y|Marcador da placa: deslocamento Y|Метка индикатора: смещение Y|이름표 표시 Y 위치 조정|名條標記Y偏移
手动距离（码）|Manual range (yards)|Manuelle Reichweite (Meter)|Portée manuelle (mètres)|Alcance manual (metros)|Portata manuale (metri)|Alcance manual (metros)|Радиус вручную (м)|수동 거리 (미터)|手動距離（碼）
按职业填写技能名称或ID，以技能射程判断距离；勾选手动距离后使用设定码数。无法判定时不提示。|Enter a spell name or ID for each class to check range. Enable manual range to use the selected distance. No warning appears if range cannot be determined.|Pro Klasse einen Zaubernamen oder eine ID zur Reichweitenprüfung eingeben. Bei manueller Reichweite gilt der eingestellte Abstand. Ist keine Prüfung möglich, erscheint keine Warnung.|Saisissez un nom ou ID de sort par classe pour vérifier la portée. La portée manuelle utilise la distance choisie. Aucune alerte si la portée est indéterminable.|Escribe un nombre o ID de hechizo por clase para comprobar el alcance. El alcance manual usa la distancia elegida. No se avisa si no se puede determinar.|Inserisci un nome o ID di incantesimo per classe per verificare la portata. La portata manuale usa la distanza scelta. Nessun avviso se non è determinabile.|Informe um nome ou ID de feitiço por classe para verificar o alcance. O alcance manual usa a distância escolhida. Não há aviso se o alcance não puder ser determinado.|Введите название или ID заклинания для каждого класса. Для ручной проверки включите заданный радиус. Если расстояние нельзя определить, предупреждение не появится.|직업별 주문 이름 또는 ID로 사거리를 확인합니다. 수동 거리를 켜면 설정한 거리를 사용합니다. 거리를 판정할 수 없으면 알리지 않습니다.|依職業輸入技能名稱或ID，以技能射程判定距離；勾選手動距離後使用設定碼數。無法判定時不提示。
外圈缩放|Outer ring scale|Außenring – Skalierung|Échelle de l’anneau extérieur|Escala del anillo exterior|Scala anello esterno|Escala do anel externo|Масштаб внешнего кольца|외부 고리 크기|外圈縮放
旋转内环|Rotating inner ring|Rotierender Innenring|Anneau intérieur rotatif|Anillo interior giratorio|Anello interno rotante|Anel interno giratório|Вращающееся внутреннее кольцо|회전하는 내부 고리|旋轉內環
旋转内环缩放|Rotating inner ring scale|Innenring – Skalierung|Échelle de l’anneau intérieur|Escala del anillo interior|Scala anello interno|Escala do anel interno|Масштаб внутреннего кольца|회전 내부 고리 크기|旋轉內環縮放
旋转内环颜色|Rotating inner ring color|Innenring – Farbe|Couleur de l’anneau intérieur|Color del anillo interior|Colore anello interno|Cor do anel interno|Цвет внутреннего кольца|회전 내부 고리 색상|旋轉內環顏色
玻璃材质|Glass texture|Glastextur|Texture du verre|Textura de cristal|Texture del vetro|Textura do vidro|Текстура стекла|유리 텍스처|玻璃材質
玻璃缩放|Glass scale|Glas – Skalierung|Échelle du verre|Escala del cristal|Scala del vetro|Escala do vidro|Масштаб стекла|유리 크기|玻璃縮放
玻璃透明度|Glass opacity|Glas – Deckkraft|Opacité du verre|Opacidad del cristal|Opacità del vetro|Opacidade do vidro|Непрозрачность стекла|유리 불투명도|玻璃透明度
游戏默认|Game default|Spielstandard|Valeur du jeu|Predeterminado del juego|Predefinito del gioco|Padrão do jogo|По умолчанию в игре|게임 기본값|遊戲預設
游戏框体尚未就绪，请稍后重试。|The game frame is not ready. Please try again shortly.|Das Spielfenster ist noch nicht bereit. Bitte später erneut versuchen.|Le cadre du jeu n’est pas prêt. Réessayez dans un instant.|El marco del juego aún no está listo. Inténtalo de nuevo en un momento.|Il riquadro del gioco non è pronto. Riprova tra poco.|O quadro do jogo ainda não está pronto. Tente novamente em breve.|Игровая рамка ещё не готова. Повторите попытку позже.|게임 프레임이 아직 준비되지 않았습니다. 잠시 후 다시 시도하세요.|遊戲框體尚未就緒，請稍後重試。
选择元素（|Select element (|Element wählen (|Choisir un élément (|Seleccionar elemento (|Seleziona elemento (|Selecionar elemento (|Выбрать элемент (|요소 선택 (|選擇元素（
开怪倒计时|Pull countdown|Pull-Countdown|Compte à rebours avant combat|Cuenta atrás de combate|Conto alla rovescia del combattimento|Contagem para iniciar combate|Отсчёт до боя|전투 시작 초읽기|開怪倒數
名称|Name|Name|Nom|Nombre|Nome|Nome|Имя|이름|名稱
单位名称|Unit name|Einheitenname|Nom de l’unité|Nombre de unidad|Nome unità|Nome da unidade|Имя персонажа|유닛 이름|單位名稱
单位名字|Unit name|Einheitenname|Nom de l’unité|Nombre de unidad|Nome unità|Nome da unidade|Имя персонажа|유닛 이름|單位名稱
光环类型|Aura type|Auratyp|Type d’aura|Tipo de aura|Tipo di aura|Tipo de aura|Тип ауры|오라 유형|光環類型
光环层数|Aura stacks|Aurastapel|Cumuls de l’aura|Acumulaciones de aura|Accumuli aura|Acúmulos de aura|Число эффектов ауры|오라 중첩|光環層數
光环剩余时间|Aura time remaining|Verbleibende Auradauer|Durée restante de l’aura|Duración restante del aura|Durata residua aura|Duração restante da aura|Оставшееся время ауры|오라 남은 시간|光環剩餘時間
增益|Buff|Stärkung|Amélioration|Beneficio|Beneficio|Benefício|Положительный эффект|강화 효과|增益
减益|Debuff|Schwächung|Affaiblissement|Perjuicio|Maleficio|Penalidade|Отрицательный эффект|약화 효과|減益
图标间距|Icon spacing|Symbolabstand|Espacement des icônes|Espaciado de iconos|Spaziatura icone|Espaçamento dos ícones|Интервал значков|아이콘 간격|圖示間距
图标上限|Maximum icons|Maximale Symbole|Nombre maximal d’icônes|Máximo de iconos|Icone massime|Máximo de ícones|Максимум значков|최대 아이콘 수|圖示數量上限
内容|Content|Inhalt|Contenu|Contenido|Contenuto|Conteúdo|Содержимое|내용|內容
数据单位|Unit|Einheit|Unité|Unidad|Unità|Unidade|Единица|단위|資料單位
固定内容|Static content|Fester Inhalt|Contenu fixe|Contenido fijo|Contenuto fisso|Conteúdo fixo|Фиксированное содержимое|고정 내용|固定內容
固定文字|Static text|Fester Text|Texte fixe|Texto fijo|Testo fisso|Texto fixo|Фиксированный текст|고정 텍스트|固定文字
生命进度|Health fill|Lebensfüllung|Remplissage de vie|Relleno de salud|Riempimento salute|Preenchimento de vida|Заполнение здоровья|생명력 채움|生命填充
资源进度|Power fill|Ressourcenfüllung|Remplissage de ressource|Relleno de recursos|Riempimento risorse|Preenchimento de recursos|Заполнение ресурсов|자원 채움|資源填充
生命数值|Health value|Lebenswert|Valeur de vie|Valor de salud|Valore salute|Valor de vida|Значение здоровья|생명력 수치|生命數值
资源数值|Power value|Ressourcenwert|Valeur de ressource|Valor de recursos|Valore risorse|Valor de recursos|Значение ресурсов|자원 수치|資源數值
生命百分比|Health percentage|Leben in Prozent|Pourcentage de vie|Porcentaje de salud|Percentuale salute|Porcentagem de vida|Процент здоровья|생명력 백분율|生命百分比
资源百分比|Power percentage|Ressourcen in Prozent|Pourcentage de ressource|Porcentaje de recursos|Percentuale risorse|Porcentagem de recursos|Процент ресурсов|자원 백분율|資源百分比
施法进度|Cast progress|Zauberfortschritt|Progression de l’incantation|Progreso de lanzamiento|Avanzamento lancio|Progresso de lançamento|Прогресс заклинания|시전 진행|施法進度
施法名称|Spell name|Zaubername|Nom du sort|Nombre del hechizo|Nome incantesimo|Nome do feitiço|Название заклинания|주문 이름|法術名稱
施法剩余时间|Cast time remaining|Verbleibende Zauberzeit|Temps d’incantation restant|Tiempo de lanzamiento restante|Tempo di lancio residuo|Tempo de lançamento restante|Оставшееся время заклинания|시전 남은 시간|施法剩餘時間
施法图标|Spell icon|Zaubersymbol|Icône du sort|Icono del hechizo|Icona incantesimo|Ícone do feitiço|Значок заклинания|주문 아이콘|法術圖示
施法条宽度|Cast bar width|Zauberleiste – Breite|Largeur de la barre d’incantation|Ancho de barra de lanzamiento|Larghezza barra di lancio|Largura da barra de lançamento|Ширина полосы заклинания|시전 바 너비|施法條寬度
施法条高度|Cast bar height|Zauberleiste – Höhe|Hauteur de la barre d’incantation|Alto de barra de lanzamiento|Altezza barra di lancio|Altura da barra de lançamento|Высота полосы заклинания|시전 바 높이|施法條高度
反向填充|Reverse fill|Füllrichtung umkehren|Inverser le remplissage|Invertir relleno|Inverti riempimento|Inverter preenchimento|Обратное заполнение|채우기 방향 반전|反向填充
横向裁切|Horizontal crop|Horizontal zuschneiden|Rognage horizontal|Recorte horizontal|Ritaglio orizzontale|Recorte horizontal|Обрезка по горизонтали|가로 자르기|橫向裁切
纵向裁切|Vertical crop|Vertikal zuschneiden|Rognage vertical|Recorte vertical|Ritaglio verticale|Recorte vertical|Обрезка по вертикали|세로 자르기|縱向裁切
图集行数|Atlas rows|Atlaszeilen|Lignes de l’atlas|Filas del atlas|Righe dell’atlante|Linhas do atlas|Строк в атласе|아틀라스 행 수|圖集列數（縱向）
图集列数|Atlas columns|Atlasspalten|Colonnes de l’atlas|Columnas del atlas|Colonne dell’atlante|Colunas do atlas|Столбцов в атласе|아틀라스 열 수|圖集行數（橫向）
有效帧数|Frame count|Anzahl der Frames|Nombre d’images|Número de fotogramas|Numero di fotogrammi|Número de quadros|Число кадров|유효 프레임 수|有效影格數
播放帧率|Frame rate|Bildrate|Images par seconde|Fotogramas por segundo|Fotogrammi al secondo|Quadros por segundo|Частота кадров|재생 프레임 속도|播放影格率
播放方式|Playback|Wiedergabe|Lecture|Reproducción|Riproduzione|Reprodução|Воспроизведение|재생 방식|播放方式
循环|Loop|Schleife|Boucle|Bucle|Ciclo|Repetir|Цикл|반복|循環
往返|Ping-pong|Vor und zurück|Aller-retour|Ida y vuelta|Avanti e indietro|Ida e volta|Вперёд и назад|왕복|往返
单次|Once|Einmal|Une fois|Una vez|Una volta|Uma vez|Один раз|한 번|單次
模型 ID|Model ID|Modell-ID|ID du modèle|ID de modelo|ID modello|ID do modelo|ID модели|모델 ID|模型ID
模型缩放|Model scale|Modellskalierung|Échelle du modèle|Escala del modelo|Scala modello|Escala do modelo|Масштаб модели|모델 크기|模型縮放
原始显示条件|Display conditions|Anzeigebedingungen|Conditions d’affichage|Condiciones de visualización|Condizioni di visualizzazione|Condições de exibição|Условия отображения|표시 조건|顯示條件
跟随所属单位显示|Show with its unit|Mit zugehöriger Einheit anzeigen|Afficher avec l’unité associée|Mostrar con su unidad|Mostra con l’unità associata|Mostrar com a unidade associada|Показывать вместе с персонажем|소속 유닛과 함께 표시|跟隨所屬單位顯示
共享头像单位|Shared portrait unit|Einheit des gemeinsamen Porträts|Unité du portrait partagé|Unidad del retrato compartido|Unità ritratto condiviso|Unidade do retrato compartilhado|Персонаж общего портрета|공유 초상화 유닛|共用頭像單位
贴图|Texture|Textur|Texture|Textura|Texture|Textura|Текстура|텍스처|貼圖
贴图旋转|Texture rotation|Texturdrehung|Rotation de la texture|Rotación de textura|Rotazione texture|Rotação da textura|Поворот текстуры|텍스처 회전|貼圖旋轉
素材路径|Asset path|Dateipfad|Chemin du fichier|Ruta del recurso|Percorso risorsa|Caminho do recurso|Путь к ресурсу|리소스 경로|素材路徑
从素材库替换…|Replace from asset library…|Aus Medienbibliothek ersetzen…|Remplacer depuis la bibliothèque…|Reemplazar desde la biblioteca…|Sostituisci dalla libreria…|Substituir pela biblioteca…|Заменить из библиотеки…|리소스 라이브러리에서 교체…|從素材庫替換…
素材库 · 点击替换当前元素|Asset library · Click to replace the selected element|Medienbibliothek · Zum Ersetzen des Elements klicken|Bibliothèque · Cliquez pour remplacer l’élément sélectionné|Biblioteca · Haz clic para reemplazar el elemento|Libreria · Fai clic per sostituire l’elemento|Biblioteca · Clique para substituir o elemento|Библиотека · Нажмите, чтобы заменить элемент|리소스 라이브러리 · 클릭하여 선택한 요소 교체|素材庫 · 點擊替換目前元素
混合|Blend mode|Mischmodus|Mode de fusion|Modo de mezcla|Metodo di fusione|Modo de mesclagem|Режим наложения|혼합 모드|混合模式
正常|Normal|Normal|Normal|Normal|Normale|Normal|Обычный|일반|正常
叠加发光|Additive glow|Additives Leuchten|Lueur additive|Brillo aditivo|Bagliore additivo|Brilho aditivo|Аддитивное свечение|가산 발광|疊加發光
正片叠底|Multiply|Multiplizieren|Produit|Multiplicar|Moltiplica|Multiplicar|Умножение|곱하기|色彩增值
颜色（0～1）|Color (0–1)|Farbe (0–1)|Couleur (0–1)|Color (0–1)|Colore (0–1)|Cor (0–1)|Цвет (0–1)|색상 (0–1)|顏色（0～1）
红色 R|Red R|Rot R|Rouge R|Rojo R|Rosso R|Vermelho R|Красный R|빨강 R|紅色R
绿色 G|Green G|Grün G|Vert G|Verde G|Verde G|Verde G|Зелёный G|초록 G|綠色G
蓝色 B|Blue B|Blau B|Bleu B|Azul B|Blu B|Azul B|Синий B|파랑 B|藍色B
透明度 A|Opacity A|Deckkraft A|Opacité A|Opacidad A|Opacità A|Opacidade A|Непрозрачность A|불투명도 A|透明度A
进度与序列帧|Fill and animation|Füllung und Animation|Remplissage et animation|Relleno y animación|Riempimento e animazione|Preenchimento e animação|Заполнение и анимация|채움 및 애니메이션|填充與序列動畫
图标|Icon|Symbol|Icône|Icono|Icona|Ícone|Значок|아이콘|圖示
光环图标组|Aura icons|Aurasymbole|Icônes d’auras|Iconos de auras|Icone aura|Ícones de auras|Значки аур|오라 아이콘|光環圖示組
玩家资源图标|Player resource icons|Ressourcensymbole des Spielers|Icônes de ressources du joueur|Iconos de recursos del jugador|Icone risorse giocatore|Ícones de recursos do jogador|Значки ресурсов игрока|플레이어 자원 아이콘|玩家資源圖示
头像|Portrait|Porträt|Portrait|Retrato|Ritratto|Retrato|Портрет|초상화|頭像
边框|Border|Rahmen|Bordure|Borde|Bordo|Borda|Рамка|테두리|邊框
高光|Highlight|Hervorhebung|Surbrillance|Resaltado|Evidenziazione|Realce|Подсветка|강조|高亮
光效|Glow|Leuchten|Lueur|Brillo|Bagliore|Brilho|Свечение|발광|光效
序列帧特效|Flipbook animation|Einzelbildanimation|Animation par images|Animación por fotogramas|Animazione a fotogrammi|Animação por quadros|Покадровая анимация|프레임 애니메이션|序列影格特效
模型特效|Model effect|Modelleffekt|Effet de modèle|Efecto de modelo|Effetto modello|Efeito de modelo|Эффект модели|모델 효과|模型特效
文字|Text|Text|Texte|Texto|Testo|Texto|Текст|텍스트|文字
进度填充|Bar fill|Leistenfüllung|Remplissage de barre|Relleno de barra|Riempimento barra|Preenchimento de barra|Заполнение полосы|바 채움|進度填充
点击区域|Click area|Klickbereich|Zone cliquable|Área de clic|Area cliccabile|Área de clique|Область нажатия|클릭 영역|點擊區域
分类|Classification|Klassifizierung|Classification|Clasificación|Classificazione|Classificação|Классификация|분류|分類
友方|Friendly|Freundlich|Amical|Amistoso|Amichevole|Amigável|Дружественный|우호적|友方
队长|Leader|Anführer|Chef|Líder|Capogruppo|Líder|Лидер|파티장|隊長
施法中|Casting|Zaubernd|En cours d’incantation|Lanzando|In lancio|Lançando|Применяет заклинание|시전 중|施法中
单位存在|Unit exists|Einheit vorhanden|Unité présente|Unidad existente|Unità presente|Unidade presente|Персонаж существует|유닛 존재|單位存在
炉石|Hearthstone|Ruhestein|Pierre de foyer|Piedra de hogar|Pietra del ritorno|Pedra de Regresso|Камень возвращения|귀환석|爐石
团队标记|Raid marker|Schlachtzugsmarkierung|Marqueur de raid|Marcador de banda|Indicatore incursione|Marcador de raide|Метка рейда|공격대 징표|團隊標記
目标的目标|Target of target|Ziel des Ziels|Cible de la cible|Objetivo del objetivo|Bersaglio del bersaglio|Alvo do alvo|Цель цели|대상의 대상|目標的目標
技能名称/技能ID|Spell name / ID|Zaubername / ID|Nom / ID du sort|Nombre / ID de hechizo|Nome / ID incantesimo|Nome / ID do feitiço|Название / ID заклинания|주문 이름 / ID|技能名稱／ID
手动设置距离|Set range manually|Reichweite manuell festlegen|Définir la portée manuellement|Definir alcance manual|Imposta portata manuale|Definir alcance manual|Задать радиус вручную|거리 수동 설정|手動設定距離
客户端按距离档位检测；确认超出设定距离时显示 X。|The client checks range brackets. X appears when the target is confirmed beyond the selected range.|Der Client prüft Entfernungsstufen. X erscheint, wenn das Ziel sicher außerhalb der eingestellten Reichweite ist.|Le client vérifie des paliers de distance. X apparaît si la cible est confirmée hors de portée.|El cliente comprueba tramos de distancia. X aparece cuando se confirma que el objetivo está fuera del alcance elegido.|Il client verifica intervalli di distanza. X appare quando il bersaglio è certamente oltre la portata scelta.|O cliente verifica faixas de distância. X aparece quando o alvo está comprovadamente além do alcance escolhido.|Клиент проверяет интервалы расстояния. X появляется, когда цель точно вне заданного радиуса.|클라이언트의 거리 구간으로 확인합니다. 설정한 거리 밖에 있는 것으로 확인되면 X를 표시합니다.|客戶端依距離區間檢測；確認超出設定距離時顯示X。
拖动绿色区域移动|Drag the green area to move|Grünen Bereich zum Verschieben ziehen|Faites glisser la zone verte pour déplacer|Arrastra el área verde para mover|Trascina l’area verde per spostare|Arraste a área verde para mover|Перетащите зелёную область|초록색 영역을 드래그하여 이동|拖動綠色區域移動
从左侧列表或画布选择元素|Select an element in the list or preview|Element in Liste oder Vorschau wählen|Choisissez un élément dans la liste ou l’aperçu|Elige un elemento en la lista o vista previa|Scegli un elemento nell’elenco o nell’anteprima|Selecione um elemento na lista ou prévia|Выберите элемент в списке или предпросмотре|목록 또는 미리보기에서 요소를 선택하세요|從左側清單或預覽選擇元素
战斗中 · 可查看，脱战后可编辑|In combat · View only; edit after combat|Im Kampf · Nur Ansicht; danach bearbeitbar|En combat · Consultation seule, modification après combat|En combate · Solo lectura; edita después|In combattimento · Sola lettura; modifica dopo|Em combate · Apenas visualização; edite depois|В бою · Только просмотр; изменение после боя|전투 중 · 보기만 가능, 전투 종료 후 편집|戰鬥中 · 僅可查看，脫戰後可編輯
战斗中暂不能修改布局，脱战后即可编辑。|Layout changes are unavailable in combat. Edit after combat.|Im Kampf kann das Layout nicht geändert werden. Nach dem Kampf bearbeiten.|La disposition ne peut pas être modifiée en combat. Réessayez après le combat.|No puedes cambiar la disposición en combate. Edita al terminar.|La disposizione non può essere modificata in combattimento. Modifica dopo.|Não é possível alterar a disposição em combate. Edite após o combate.|В бою нельзя менять расположение. Редактируйте после боя.|전투 중에는 배치를 변경할 수 없습니다. 전투 종료 후 편집하세요.|戰鬥中無法修改配置，脫戰後即可編輯。
血量／能量材质不同|Health and power textures differ|Verschiedene Texturen für Leben und Ressourcen|Textures de vie et de ressource différentes|Texturas distintas de salud y recursos|Texture diverse per salute e risorse|Texturas de vida e recursos diferentes|Текстуры здоровья и ресурсов различаются|생명력과 자원 텍스처가 다릅니다|生命／能量材質不同
当前配置无法导出，请检查配置数据。|Cannot export the current settings. Check the saved data.|Die Einstellungen können nicht exportiert werden. Gespeicherte Daten prüfen.|Impossible d’exporter les réglages. Vérifiez les données enregistrées.|No se pueden exportar los ajustes. Comprueba los datos guardados.|Impossibile esportare le impostazioni. Controlla i dati salvati.|Não é possível exportar as configurações. Confira os dados salvos.|Не удалось экспортировать настройки. Проверьте сохранённые данные.|설정을 내보낼 수 없습니다. 저장된 데이터를 확인하세요.|無法匯出目前設定，請檢查設定資料。
按 Ctrl+C 复制下方字符串，分享给其他用户。|Press Ctrl+C to copy the string below and share it.|Mit Ctrl+C die Zeichenfolge unten kopieren und teilen.|Appuyez sur Ctrl+C pour copier la chaîne ci-dessous et la partager.|Pulsa Ctrl+C para copiar la cadena inferior y compartirla.|Premi Ctrl+C per copiare la stringa qui sotto e condividerla.|Pressione Ctrl+C para copiar o texto abaixo e compartilhar.|Нажмите Ctrl+C, чтобы скопировать строку ниже и поделиться ею.|Ctrl+C로 아래 문자열을 복사하여 공유하세요.|按 Ctrl+C 複製下方字串，分享給其他使用者。
粘贴配置字符串；导入后将覆盖当前全部设置。|Paste a settings string. Importing replaces all current settings.|Einstellungszeichenfolge einfügen. Der Import ersetzt alle aktuellen Einstellungen.|Collez une chaîne de réglages. L’importation remplace tous les réglages actuels.|Pega una cadena de ajustes. La importación reemplaza todos los ajustes actuales.|Incolla una stringa di impostazioni. L’importazione sostituisce tutte le impostazioni attuali.|Cole o texto de configurações. A importação substitui todas as configurações atuais.|Вставьте строку настроек. Импорт заменит все текущие настройки.|설정 문자열을 붙여 넣으세요. 가져오면 현재 설정을 모두 덮어씁니다.|貼上設定字串；匯入後將覆蓋目前所有設定。
配置字符串无效或已损坏，请检查是否完整复制。|Invalid or damaged settings string. Check that it was copied in full.|Ungültige oder beschädigte Einstellungszeichenfolge. Prüfen, ob alles kopiert wurde.|Chaîne de réglages invalide ou endommagée. Vérifiez qu’elle a été copiée en entier.|Cadena de ajustes inválida o dañada. Comprueba que se copió completa.|Stringa di impostazioni non valida o danneggiata. Verifica di averla copiata per intero.|Texto de configurações inválido ou corrompido. Confira se foi copiado por completo.|Строка настроек недействительна или повреждена. Проверьте, что она скопирована полностью.|설정 문자열이 잘못되었거나 손상되었습니다. 전체를 복사했는지 확인하세요.|設定字串無效或已損壞，請確認已完整複製。
黑名单已满，请先移除部分条目。|The exclusion list is full. Remove some entries first.|Die Ausschlussliste ist voll. Zuerst einige Einträge entfernen.|La liste d’exclusion est pleine. Supprimez d’abord quelques entrées.|La lista de exclusión está llena. Elimina algunas entradas.|L’elenco esclusioni è pieno. Rimuovi alcune voci.|A lista de exclusão está cheia. Remova algumas entradas.|Список исключений заполнен. Сначала удалите несколько записей.|제외 목록이 가득 찼습니다. 일부 항목을 먼저 삭제하세요.|排除清單已滿，請先移除部分項目。
输入技能／物品名称或 ID，点击＋添加。|Enter a spell/item name or ID, then click + to add.|Zauber-/Gegenstandsname oder ID eingeben und mit + hinzufügen.|Saisissez un nom ou ID de sort/objet, puis cliquez sur +.|Escribe un nombre o ID de hechizo/objeto y pulsa +.|Inserisci un nome o ID di incantesimo/oggetto e fai clic su +.|Informe um nome ou ID de feitiço/item e clique em +.|Введите название или ID заклинания/предмета и нажмите +.|주문/아이템 이름 또는 ID를 입력하고 +를 누르세요.|輸入技能／物品名稱或ID，點擊＋新增。
世界地图（M）|World map (M)|Weltkarte (M)|Carte du monde (M)|Mapa del mundo (M)|Mappa del mondo (M)|Mapa-múndi (M)|Карта мира (M)|세계 지도 (M)|世界地圖（M）
主菜单（Escape）|Game menu (Escape)|Spielmenü (Escape)|Menu du jeu (Échap)|Menú del juego (Escape)|Menu di gioco (Esc)|Menu do jogo (Esc)|Меню игры (Esc)|게임 메뉴 (Esc)|主選單（Escape）
任务日志（L）|Quest log (L)|Questlog (L)|Journal des quêtes (L)|Registro de misiones (L)|Registro missioni (L)|Registro de missões (L)|Журнал заданий (L)|퀘스트 목록 (L)|任務日誌（L）
社交（O）|Social (O)|Kontakte (O)|Social (O)|Social (O)|Sociale (O)|Social (O)|Общение (O)|커뮤니티 (O)|社交（O）
背包（B）|Bags (B)|Taschen (B)|Sacs (B)|Bolsas (B)|Borse (B)|Bolsas (B)|Сумки (B)|가방 (B)|背包（B）
角色信息（C）|Character (C)|Charakter (C)|Personnage (C)|Personaje (C)|Personaggio (C)|Personagem (C)|Персонаж (C)|캐릭터 정보 (C)|角色資訊（C）
集结号|Meeting Horn|Meeting Horn|Meeting Horn|Meeting Horn|Meeting Horn|Meeting Horn|Meeting Horn|Meeting Horn|集結號
集结号或集合石插件尚未启用。|The Meeting Horn or Meeting Stone addon is not enabled.|Meeting Horn oder Meeting Stone ist nicht aktiviert.|L’addon Meeting Horn ou Meeting Stone n’est pas activé.|El addon Meeting Horn o Meeting Stone no está activado.|L’addon Meeting Horn o Meeting Stone non è attivo.|O addon Meeting Horn ou Meeting Stone não está ativado.|Аддон Meeting Horn или Meeting Stone не включён.|Meeting Horn 또는 Meeting Stone 애드온이 활성화되지 않았습니다.|集結號或集合石插件尚未啟用。
当前客户端不支持此菜单入口。|This menu is unavailable in the current client.|Dieses Menü ist im aktuellen Client nicht verfügbar.|Ce menu n’est pas disponible sur ce client.|Este menú no está disponible en el cliente actual.|Questo menu non è disponibile nel client attuale.|Este menu não está disponível no cliente atual.|Это меню недоступно в текущем клиенте.|현재 클라이언트에서는 이 메뉴를 지원하지 않습니다.|目前客戶端不支援此選單入口。
进入战斗提示|Entering combat alert|Hinweis bei Kampfbeginn|Alerte d’entrée en combat|Aviso al entrar en combate|Avviso inizio combattimento|Aviso ao entrar em combate|Оповещение о начале боя|전투 시작 알림|進入戰鬥提示
离开战斗提示|Leaving combat alert|Hinweis bei Kampfende|Alerte de sortie de combat|Aviso al salir del combate|Avviso fine combattimento|Aviso ao sair do combate|Оповещение о завершении боя|전투 종료 알림|離開戰鬥提示
当前没有可用的开怪倒计时接口。|No pull countdown API is available.|Keine Schnittstelle für einen Pull-Countdown verfügbar.|Aucune interface de compte à rebours de combat n’est disponible.|No hay una interfaz disponible para la cuenta atrás de combate.|Nessuna interfaccia disponibile per il conto alla rovescia del combattimento.|Nenhuma interface de contagem para combate está disponível.|Интерфейс отсчёта до боя недоступен.|전투 시작 초읽기 기능을 사용할 수 없습니다.|目前沒有可用的開怪倒數介面。
寻求组队：右键加入／离开频道|Looking for Group: right-click to join/leave the channel|Suche nach Gruppe: Rechtsklick zum Beitreten/Verlassen|Recherche de groupe : clic droit pour rejoindre/quitter|Buscar grupo: clic derecho para entrar/salir|Ricerca gruppo: clic destro per entrare/uscire|Procurando grupo: clique direito para entrar/sair|Поиск группы: ПКМ для входа/выхода из канала|파티 찾기: 우클릭으로 채널 입장/퇴장|尋求組隊：右鍵加入／離開頻道
大脚世界频道：右键加入／离开频道|Bigfoot World: right-click to join/leave the channel|Bigfoot World: Rechtsklick zum Beitreten/Verlassen|Bigfoot World : clic droit pour rejoindre/quitter|Bigfoot World: clic derecho para entrar/salir|Bigfoot World: clic destro per entrare/uscire|Bigfoot World: clique direito para entrar/sair|Bigfoot World: ПКМ для входа/выхода из канала|Bigfoot World: 우클릭으로 채널 입장/퇴장|大腳世界頻道：右鍵加入／離開頻道
尚未加入此频道，请右键按钮加入。|You have not joined this channel. Right-click the button to join.|Diesem Kanal noch nicht beigetreten. Zum Beitreten den Knopf rechtsklicken.|Vous n’avez pas rejoint ce canal. Faites un clic droit sur le bouton.|No te has unido a este canal. Haz clic derecho en el botón.|Non sei in questo canale. Fai clic destro sul pulsante per entrare.|Você ainda não entrou neste canal. Clique com o botão direito para entrar.|Вы ещё не вошли в канал. Нажмите ПКМ на кнопке для входа.|이 채널에 참여하지 않았습니다. 버튼을 우클릭하여 참여하세요.|尚未加入此頻道，請右鍵點擊按鈕加入。
已加入频道：%s（当前窗口已启用接收）。|Joined channel: %s (enabled in this chat window).|Kanal beigetreten: %s (Empfang in diesem Chatfenster aktiviert).|Canal rejoint : %s (affiché dans cette fenêtre de discussion).|Canal unido: %s (activado en esta ventana de chat).|Canale raggiunto: %s (attivo in questa finestra di chat).|Entrou no canal: %s (ativado nesta janela de bate-papo).|Вход в канал: %s (включён в этом окне чата).|채널 참여: %s (현재 대화창에 표시됩니다).|已加入頻道：%s（目前視窗已啟用接收）。
已离开频道：%s。|Left channel: %s.|Kanal verlassen: %s.|Canal quitté : %s.|Has salido del canal: %s.|Canale lasciato: %s.|Saiu do canal: %s.|Выход из канала: %s.|채널 나가기: %s.|已離開頻道：%s。
频道操作未完成：%s，请稍后重试。|Channel action failed: %s. Please try again later.|Kanalaktion fehlgeschlagen: %s. Bitte später erneut versuchen.|Action sur le canal échouée : %s. Réessayez plus tard.|Error de acción en el canal: %s. Inténtalo de nuevo más tarde.|Operazione sul canale fallita: %s. Riprova più tardi.|Ação no canal falhou: %s. Tente novamente mais tarde.|Действие с каналом не выполнено: %s. Повторите позже.|채널 작업 실패: %s. 잠시 후 다시 시도하세요.|頻道操作未完成：%s，請稍後重試。
开怪倒计时：左键 10 秒，右键取消|Pull timer: left-click for 10 seconds, right-click to cancel|Pull-Countdown: Linksklick für 10 Sekunden, Rechtsklick zum Abbrechen|Compte à rebours : clic gauche pour 10 secondes, clic droit pour annuler|Cuenta atrás: clic izquierdo para 10 segundos, derecho para cancelar|Conto alla rovescia: clic sinistro per 10 secondi, destro per annullare|Contagem: clique esquerdo para 10 segundos, direito para cancelar|Отсчёт до боя: ЛКМ — 10 сек., ПКМ — отмена|전투 초읽기: 좌클릭 10초, 우클릭 취소|開怪倒數：左鍵10秒，右鍵取消
骰子：Shift 点击固定掷出 100|Roll: Shift-click to roll exactly 100|Würfeln: Umschalt-Klick würfelt genau 100|Jet : Maj-clic pour obtenir exactement 100|Dados: Mayús-clic para sacar exactamente 100|Dado: Maiusc-clic per ottenere esattamente 100|Dado: Shift-clique para tirar exatamente 100|Бросок: Shift-клик для результата ровно 100|주사위: Shift 클릭으로 항상 100 굴림|骰子：Shift 點擊固定擲出100
任务经验：%s（%.1f%%）|Completed quest XP: %s (%.1f%%)|EP aus abgeschlossenen Quests: %s (%.1f%%)|EXP des quêtes terminées : %s (%.1f%%)|EXP de misiones completadas: %s (%.1f%%)|PE missioni completate: %s (%.1f%%)|EXP de missões concluídas: %s (%.1f%%)|Опыт за выполненные задания: %s (%.1f%%)|완료한 퀘스트 경험치: %s (%.1f%%)|已完成任務經驗：%s（%.1f%%）
休息双倍：%s（%.1f%%）|Rested XP: %s (%.1f%%)|Erholungsbonus: %s (%.1f%%)|EXP de repos : %s (%.1f%%)|EXP de descanso: %s (%.1f%%)|PE riposo: %s (%.1f%%)|EXP de descanso: %s (%.1f%%)|Опыт за отдых: %s (%.1f%%)|휴식 경험치: %s (%.1f%%)|休息雙倍：%s（%.1f%%）
未完成任务经验：%s|Incomplete quest XP: %s|EP aus offenen Quests: %s|EXP des quêtes inachevées : %s|EXP de misiones incompletas: %s|PE missioni incomplete: %s|EXP de missões incompletas: %s|Опыт за незавершённые задания: %s|미완료 퀘스트 경험치: %s|未完成任務經驗：%s
经验/小时：%s|XP/hour: %s|EP/Stunde: %s|EXP/heure : %s|EXP/hora: %s|PE/ora: %s|EXP/hora: %s|Опыт/час: %s|시간당 경험치: %s|經驗／小時：%s
预计升级时间：|Time to level: |Zeit bis Stufenaufstieg: |Temps avant le prochain niveau : |Tiempo hasta subir de nivel: |Tempo al prossimo livello: |Tempo até subir de nível: |Время до нового уровня: |다음 레벨까지: |預計升級時間：
本次在线：|Session time: |Aktuelle Spielzeit: |Durée de la session : |Tiempo de sesión: |Durata sessione: |Tempo da sessão: |Время сеанса: |현재 접속 시간: |本次在線：
中文|Chinese|Chinesisch|Chinois|Chino|Cinese|Chinês|Китайский|중국어|中文
MangUI 单位框体|MangUI Unit Frames|MangUI Einheitenfenster|MangUI Cadres d’unités|MangUI Marcos de unidad|MangUI Riquadri unità|MangUI Quadros de unidades|MangUI Рамки персонажей|MangUI 유닛 프레임|MangUI 單位框體
点击打开设计器；拖动调整按钮位置|Click to open settings; drag to move the icon|Klicken öffnet Einstellungen; Ziehen verschiebt das Symbol|Cliquez pour ouvrir les réglages ; glissez pour déplacer l’icône|Haz clic para abrir ajustes; arrastra para mover el icono|Fai clic per aprire le impostazioni; trascina per spostare l’icona|Clique para abrir configurações; arraste para mover o ícone|Нажмите для настроек; перетащите, чтобы переместить значок|클릭하여 설정 열기, 드래그하여 아이콘 이동|點擊開啟設定；拖動調整圖示位置
已加载。/mui 打开设计器，小地图金色图标为入口。| loaded. Open settings with /mui or the gold minimap icon.| geladen. Einstellungen mit /mui oder dem goldenen Minikartensymbol öffnen.| chargé. Ouvrez les réglages avec /mui ou l’icône dorée de la minicarte.| cargado. Abre los ajustes con /mui o el icono dorado del minimapa.| caricato. Apri le impostazioni con /mui o l’icona dorata della minimappa.| carregado. Abra as configurações com /mui ou o ícone dourado do minimapa.| загружен. Откройте настройки через /mui или золотой значок миникарты.| 로드되었습니다. /mui 또는 미니맵의 금색 아이콘으로 설정을 여세요.| 已載入。輸入 /mui 或點擊小地圖金色圖示開啟設定。
MangUI 的CPU使用率，每秒更新。|MangUI CPU usage, updated every second.|CPU-Auslastung von MangUI, jede Sekunde aktualisiert.|Utilisation CPU de MangUI, actualisée chaque seconde.|Uso de CPU de MangUI, actualizado cada segundo.|Uso CPU di MangUI, aggiornato ogni secondo.|Uso de CPU do MangUI, atualizado a cada segundo.|Использование процессора MangUI, обновляется каждую секунду.|MangUI CPU 사용률이며 매초 갱신됩니다.|MangUI 的CPU使用率，每秒更新。
按插件执行时间占单线程时间的比例计算。|Calculated from addon execution time as a share of single-thread time.|Aus Addon-Laufzeit als Anteil der Zeit eines Threads berechnet.|Calculée à partir du temps d’exécution de l’addon par rapport à celui d’un thread.|Se calcula como tiempo de ejecución del addon sobre el tiempo de un hilo.|Calcolato dal tempo di esecuzione dell’addon rispetto al tempo di un singolo thread.|Calculado pelo tempo de execução do addon em relação ao tempo de uma única thread.|Рассчитывается как доля времени выполнения аддона во времени одного потока.|단일 스레드 시간 대비 애드온 실행 시간의 비율로 계산합니다.|依插件執行時間占單執行緒時間的比例計算。
CPU统计未开启。输入 /console scriptProfile 1 后 /reload。|CPU profiling is off. Enter /console scriptProfile 1, then /reload.|CPU-Profiling ist aus. /console scriptProfile 1 und danach /reload eingeben.|Le profilage CPU est désactivé. Entrez /console scriptProfile 1, puis /reload.|El perfil de CPU está desactivado. Escribe /console scriptProfile 1 y luego /reload.|Profilazione CPU disattivata. Digita /console scriptProfile 1, poi /reload.|O perfil de CPU está desativado. Digite /console scriptProfile 1 e depois /reload.|Профилирование CPU отключено. Введите /console scriptProfile 1, затем /reload.|CPU 측정이 꺼져 있습니다. /console scriptProfile 1 입력 후 /reload 하세요.|CPU統計未開啟。輸入 /console scriptProfile 1 後執行 /reload。
当前客户端未提供可用的CPU统计数据。|This client provides no usable CPU statistics.|Dieser Client liefert keine nutzbaren CPU-Statistiken.|Ce client ne fournit pas de statistiques CPU utilisables.|Este cliente no proporciona estadísticas de CPU utilizables.|Questo client non fornisce statistiche CPU utilizzabili.|Este cliente não fornece estatísticas de CPU utilizáveis.|Клиент не предоставляет доступную статистику CPU.|현재 클라이언트에서 사용 가능한 CPU 통계를 제공하지 않습니다.|目前客戶端未提供可用的CPU統計資料。
正在采集CPU数据…|Collecting CPU data…|CPU-Daten werden erfasst…|Collecte des données CPU…|Recopilando datos de CPU…|Raccolta dati CPU…|Coletando dados de CPU…|Сбор данных CPU…|CPU 데이터 수집 중…|正在收集CPU資料…
恢复“|Restore defaults for “|Standardlayout für „|Rétablir la disposition de « |Restaurar la disposición de «|Ripristinare la disposizione di «|Restaurar a disposição de “|Восстановить расположение «|“|還原「
”的默认布局？只会重置当前框体。|”? Only this frame will be reset.|“ wiederherstellen? Nur dieses Fenster wird zurückgesetzt.| » ? Seul ce cadre sera réinitialisé.|»? Solo se restablecerá este marco.|»? Verrà ripristinato solo questo riquadro.|”? Apenas este quadro será redefinido.|»? Будет сброшена только эта рамка.|”의 기본 배치를 복원할까요? 이 프레임만 초기화됩니다.|」的預設配置？只會重設目前框體。
 · 拖动绿色区域| · Drag the green area| · Grünen Bereich ziehen| · Glissez la zone verte| · Arrastra el área verde| · Trascina l’area verde| · Arraste a área verde| · Перетащите зелёную область| · 초록색 영역 드래그| · 拖動綠色區域
 · 双击 | · Double-click | · Doppelklick | · Double-clic | · Doble clic | · Doppio clic | · Clique duplo | · Двойной щелчок | · 두 번 클릭 | · 按兩下
 个框体| frames| Fenster| cadres| marcos| riquadri| quadros| рамок|개 프레임| 個框體
非 |Not |Nicht |Pas |No |Non |Não |Не |아님: |非 
选择元素：|Select element:|Element wählen:|Choisir un élément :|Seleccionar elemento:|Seleziona elemento:|Selecionar elemento:|Выберите элемент:|요소 선택:|選擇元素：
可拖动此组合的子项 · 目标头像固定居中|Drag this group’s elements · The target portrait stays centered|Elemente dieser Gruppe ziehen · Zielporträt bleibt zentriert|Déplacez les éléments du groupe · Portrait de cible centré|Arrastra elementos del grupo · El retrato del objetivo queda centrado|Trascina gli elementi del gruppo · Il ritratto resta al centro|Arraste os elementos do grupo · O retrato do alvo fica centralizado|Перетаскивайте элементы группы · Портрет цели остаётся в центре|그룹 요소 드래그 가능 · 대상 초상화는 중앙 고정|可拖動此群組的元素 · 目標頭像固定置中
解锁移动模式|Unlock movement|Verschieben freigeben|Déverrouiller le déplacement|Desbloquear movimiento|Sblocca spostamento|Desbloquear movimento|Разблокировать перемещение|이동 모드 잠금 해제|解鎖移動模式
完成移动|Finish moving|Fertig|Terminer|Terminar|Fine|Concluir|Готово|이동 완료|完成移動
生命进度条颜色/渐变开始颜色|Health / gradient start color|Leben / Verlaufstart|Vie / début du dégradé|Salud / inicio del degradado|Salute / inizio sfumatura|Vida / início do gradiente|Здоровье / начало градиента|생명력 / 그라데이션 시작 색상|生命條顏色／漸層起始顏色
进度条颜色/渐变开始颜色|Bar / gradient start color|Leiste / Verlaufstart|Barre / début du dégradé|Barra / inicio del degradado|Barra / inizio sfumatura|Barra / início do gradiente|Полоса / начало градиента|바 / 그라데이션 시작 색상|進度條顏色／漸層起始顏色
渐变结束颜色|Gradient end color|Verlaufende|Fin du dégradé|Fin del degradado|Fine sfumatura|Fim do gradiente|Конец градиента|그라데이션 끝 색상|漸層結束顏色
目标的目标框体|Target of target frame|Ziel des Ziels|Cible de la cible|Objetivo del objetivo|Bersaglio del bersaglio|Alvo do alvo|Рамка цели цели|대상의 대상 프레임|目標的目標框體
玩家与目标主框体|Player and target frames|Spieler und Ziel|Joueur et cible|Jugador y objetivo|Giocatore e bersaglio|Jogador e alvo|Игрок и цель|플레이어 및 대상 프레임|玩家與目標主框體
聊天与功能按钮|Chat and utility buttons|Chat und Funktionen|Discussion et utilitaires|Chat y utilidades|Chat e funzioni|Chat e utilidades|Чат и функции|대화 및 기능 버튼|聊天與功能按鈕
进入和离开战斗提示|Combat entry/exit alerts|Kampfbeginn und -ende|Entrée et sortie de combat|Entrada y salida de combate|Inizio e fine combattimento|Entrada e saída de combate|Начало и завершение боя|전투 시작 및 종료 알림|進入與離開戰鬥提示
技能冷却监控|Cooldown monitor|Abklingzeiten|Suivi des temps de recharge|Monitor de reutilización|Monitor recuperi|Monitor de recargas|Контроль перезарядки|재사용 대기시간 감시|技能冷卻監控
鼠标光圈提示|Mouse highlight|Mausmarkierung|Halo de la souris|Halo del cursor|Alone del mouse|Destaque do cursor|Подсветка курсора|마우스 원형 강조|滑鼠光圈提示
外圈颜色|Outer ring color|Außenring – Farbe|Couleur de l’anneau extérieur|Color del anillo exterior|Colore anello esterno|Cor do anel externo|Цвет внешнего кольца|외부 고리 색상|外圈顏色
内圈颜色|Inner ring color|Innenring – Farbe|Couleur de l’anneau intérieur|Color del anillo interior|Colore anello interno|Cor do anel interno|Цвет внутреннего кольца|내부 고리 색상|內圈顏色
GCD圈颜色|GCD ring color|GCD-Ring – Farbe|Couleur de l’anneau GCD|Color del anillo GCD|Colore anello GCD|Cor do anel GCD|Цвет кольца GCD|GCD 고리 색상|GCD圈顏色
隐藏宠物能量条|Hide pet power bar|Ressourcenleiste des Begleiters ausblenden|Masquer la barre de ressource du familier|Ocultar recursos de mascota|Nascondi risorse del famiglio|Ocultar recursos do ajudante|Скрыть полосу ресурсов питомца|소환수 자원 바 숨기기|隱藏寵物能量條
宠物头像|Pet portrait|Begleiterporträt|Portrait du familier|Retrato de mascota|Ritratto famiglio|Retrato do ajudante|Портрет питомца|소환수 초상화|寵物頭像
焦点头像|Focus portrait|Fokusporträt|Portrait de focalisation|Retrato de foco|Ritratto focus|Retrato do foco|Портрет фокуса|주시 대상 초상화|專注目標頭像
目标的目标头像|Target of target portrait|Porträt des Zielziels|Portrait de la cible de la cible|Retrato del objetivo del objetivo|Ritratto del bersaglio del bersaglio|Retrato do alvo do alvo|Портрет цели цели|대상의 대상 초상화|目標的目標頭像
宠物名称|Pet name|Begleitername|Nom du familier|Nombre de mascota|Nome famiglio|Nome do ajudante|Имя питомца|소환수 이름|寵物名稱
焦点名称|Focus name|Fokusname|Nom de focalisation|Nombre de foco|Nome focus|Nome do foco|Имя фокуса|주시 대상 이름|專注目標名稱
目标的目标名称|Target of target name|Name des Zielziels|Nom de la cible de la cible|Nombre del objetivo del objetivo|Nome del bersaglio del bersaglio|Nome do alvo do alvo|Имя цели цели|대상의 대상 이름|目標的目標名稱
生命条|Health bar|Lebensleiste|Barre de vie|Barra de salud|Barra della salute|Barra de vida|Полоса здоровья|생명력 바|生命條
施法条|Cast bar|Zauberleiste|Barre d’incantation|Barra de lanzamiento|Barra di lancio|Barra de lançamento|Полоса заклинания|시전 바|施法條
模型|Model|Modell|Modèle|Modelo|Modello|Modelo|Модель|모델|模型
进度条框体|Bar frame|Leistenrahmen|Cadre de barre|Marco de barra|Cornice della barra|Quadro da barra|Рамка полосы|바 프레임|進度條框體
精英与稀有图标|Elite and rare icons|Elite- und Seltenheitssymbole|Icônes élite et rare|Iconos de élite y raro|Icone élite e raro|Ícones de elite e raro|Значки элиты и редкости|정예 및 희귀 아이콘|精英與稀有圖示
装饰贴图与火焰动画|Decoration and flame animation|Dekoration und Flammenanimation|Décoration et animation de flammes|Decoración y animación de llamas|Decorazione e animazione fiamme|Decoração e animação de chamas|Декор и анимация пламени|장식 및 불꽃 애니메이션|裝飾貼圖與火焰動畫
最短冷却时间监控（秒）|Minimum cooldown (s)|Minimale Abklingzeit (s)|Recharge minimale (s)|Reutilización mínima (s)|Recupero minimo (s)|Recarga mínima (s)|Мин. перезарядка (с)|최소 재사용 대기시간 (초)|最短冷卻時間監控（秒）
最长冷却时间监控（秒）|Maximum cooldown (s)|Maximale Abklingzeit (s)|Recharge maximale (s)|Reutilización máxima (s)|Recupero massimo (s)|Recarga máxima (s)|Макс. перезарядка (с)|최대 재사용 대기시간 (초)|最長冷卻時間監控（秒）
倒计时时间（秒）|Pull countdown (s)|Pull-Countdown (s)|Compte à rebours (s)|Cuenta atrás (s)|Conto alla rovescia (s)|Contagem regressiva (s)|Отсчёт до боя (с)|전투 초읽기 (초)|開怪倒數時間（秒）
队员纵向间距|Member vertical spacing|Vertikaler Mitgliederabstand|Espacement vertical des membres|Espacio vertical de miembros|Spaziatura verticale membri|Espaço vertical dos membros|Интервал участников по вертикали|파티원 세로 간격|隊員縱向間距
文字Y偏移|Text Y offset|Text – Y-Versatz|Texte : décalage Y|Texto: desplazamiento Y|Testo: scostamento Y|Texto: deslocamento Y|Текст: смещение Y|텍스트 Y 위치 조정|文字Y偏移
隐藏无持续时间的增益|Hide buffs without a duration|Stärkungen ohne Dauer ausblenden|Masquer les améliorations sans durée|Ocultar beneficios sin duración|Nascondi benefici senza durata|Ocultar benefícios sem duração|Скрыть эффекты без срока действия|지속시간 없는 강화 효과 숨기기|隱藏無持續時間的增益
不监控的技能／物品|Excluded spells / items|Ausgeschlossene Zauber / Gegenstände|Sorts / objets exclus|Hechizos / objetos excluidos|Incantesimi / oggetti esclusi|Feitiços / itens excluídos|Исключённые заклинания / предметы|제외할 주문 / 아이템|不監控的技能／物品
不高兴|Unhappy|Unglücklich|Mécontent|Infeliz|Scontento|Infeliz|Недовольный|불만족|不高興
满足|Content|Zufrieden|Satisfait|Contento|Soddisfatto|Satisfeito|Довольный|만족|滿足
快乐|Happy|Glücklich|Heureux|Feliz|Felice|Feliz|Счастливый|행복|快樂
离线|Offline|Offline|Hors ligne|Desconectado|Disconnesso|Desconectado|Не в сети|오프라인|離線
预览|Preview|Vorschau|Aperçu|Vista previa|Anteprima|Prévia|Предпросмотр|미리보기|預覽
全部|All|Alle|Tous|Todo|Tutti|Todos|Все|전체|全部
中央头像|Central portrait|Zentrales Porträt|Portrait central|Retrato central|Ritratto centrale|Retrato central|Центральный портрет|중앙 초상화|中央頭像
外围特效|Outer effects|Äußere Effekte|Effets extérieurs|Efectos exteriores|Effetti esterni|Efeitos externos|Внешние эффекты|외곽 효과|外圍特效
等待初始化|Waiting for initialization|Warte auf Initialisierung|En attente d’initialisation|Esperando inicialización|In attesa di inizializzazione|Aguardando inicialização|Ожидание инициализации|초기화 대기 중|等待初始化
存在错误：|Error: |Fehler: |Erreur : |Error: |Errore: |Erro: |Ошибка: |오류: |發生錯誤：
运行中（有错误）|Running (with errors)|Aktiv (mit Fehlern)|Actif (avec erreurs)|Activo (con errores)|Attivo (con errori)|Ativo (com erros)|Работает (с ошибками)|실행 중 (오류 있음)|執行中（有錯誤）
运行中|Running|Aktiv|Actif|Activo|Attivo|Ativo|Работает|실행 중|執行中
已载入|Loaded|Geladen|Chargé|Cargado|Caricato|Carregado|Загружено|로드됨|已載入
缺失|Missing|Fehlt|Manquant|Falta|Mancante|Ausente|Отсутствует|없음|缺少
已创建|Created|Erstellt|Créé|Creado|Creato|Criado|Создано|생성됨|已建立
未创建|Not created|Nicht erstellt|Non créé|No creado|Non creato|Não criado|Не создано|생성되지 않음|未建立
 · 接口 | · Interface | · Schnittstelle | · Interface | · Interfaz | · Interfaccia | · Interface | · Интерфейс | · 인터페이스 | · 介面 
 · 小地图 | · Minimap | · Minikarte | · Minicarte | · Minimapa | · Minimappa | · Minimapa | · Миникарта | · 미니맵 | · 小地圖 
设置模块 |Settings module |Einstellungsmodul |Module de réglages |Módulo de ajustes |Modulo impostazioni |Módulo de configurações |Модуль настроек |설정 모듈 |設定模組 
配置尚未就绪。|Settings are not ready.|Einstellungen sind noch nicht bereit.|Les réglages ne sont pas prêts.|Los ajustes aún no están listos.|Le impostazioni non sono pronte.|As configurações ainda não estão prontas.|Настройки ещё не готовы.|설정이 아직 준비되지 않았습니다.|設定尚未就緒。
配置尚未就绪。输入 /mui status 查看加载状态。|Settings are not ready. Enter /mui status to check loading.|Einstellungen sind noch nicht bereit. Mit /mui status den Ladestatus prüfen.|Les réglages ne sont pas prêts. Entrez /mui status pour vérifier le chargement.|Los ajustes no están listos. Usa /mui status para comprobar la carga.|Le impostazioni non sono pronte. Digita /mui status per controllare il caricamento.|As configurações não estão prontas. Digite /mui status para verificar o carregamento.|Настройки ещё не готовы. Введите /mui status для проверки загрузки.|설정이 준비되지 않았습니다. /mui status로 로드 상태를 확인하세요.|設定尚未就緒。輸入 /mui status 查看載入狀態。
请脱离战斗后测试首领框体。|Leave combat before testing boss frames.|Zum Testen der Bossfenster den Kampf verlassen.|Quittez le combat avant de tester les cadres de boss.|Sal del combate antes de probar los marcos de jefe.|Esci dal combattimento prima di provare i riquadri dei boss.|Saia do combate antes de testar quadros de chefes.|Выйдите из боя перед проверкой рамок боссов.|전투 종료 후 우두머리 프레임을 테스트하세요.|請脫離戰鬥後測試首領框體。
配置由更新版本生成，请更新 MangUI；保存的数据未修改。|These settings were created by a newer version. Update MangUI; saved data has not been changed.|Diese Einstellungen stammen aus einer neueren Version. MangUI aktualisieren; gespeicherte Daten wurden nicht geändert.|Ces réglages proviennent d’une version plus récente. Mettez MangUI à jour ; les données n’ont pas été modifiées.|Estos ajustes son de una versión más reciente. Actualiza MangUI; los datos guardados no se han modificado.|Impostazioni create da una versione più recente. Aggiorna MangUI; i dati salvati non sono stati modificati.|Estas configurações são de uma versão mais recente. Atualize o MangUI; os dados salvos não foram alterados.|Настройки созданы более новой версией. Обновите MangUI; сохранённые данные не изменены.|더 최신 버전에서 만든 설정입니다. MangUI를 업데이트하세요. 저장된 데이터는 변경되지 않았습니다.|設定由較新版本產生，請更新 MangUI；已儲存資料未變更。
首领框体|Boss frames|Bossfenster|Cadres de boss|Marcos de jefe|Riquadri boss|Quadros de chefes|Рамки боссов|우두머리 프레임|首領框體
%d天|%dd|%dT|%dj|%dd|%dg|%dd|%dд|%d일|%d天
%d小时|%dh|%dh|%dh|%dh|%dh|%dh|%dч|%d시간|%d小時
%d分钟|%dm|%dmin|%dmin|%dmin|%dmin|%dmin|%dмин|%d분|%d分鐘
不到1分钟|< 1m|< 1min|< 1min|< 1min|< 1min|< 1min|< 1мин|1분 미만|不到1分鐘
]]
for line in rows:gmatch("[^\r\n]+")do
    local fields={};for value in line:gmatch("([^|]*)|")do fields[#fields+1]=value end
    fields[#fields+1]=line:match("([^|]*)$")
    for index,code in ipairs(codes)do M.localeTables[code][fields[1]]=fields[index+1]end
end
-- Axis suffixes use one vocabulary everywhere, including older saved labels.
local axes={
    ["头像"]={"头像X偏移","头像X偏移","头像Y偏移"},
    ["宠物头像"]={"宠物头像X偏移","宠物头像X偏移","宠物头像Y偏移"},
    ["焦点头像"]={"焦点头像X偏移","焦点头像X偏移","焦点头像Y偏移"},
    ["目标的目标头像"]={"目标的目标头像X偏移","目标的目标头像X偏移","目标的目标头像Y偏移"},
    ["宠物名称"]={"宠物名称X偏移","宠物名称X偏移","宠物名称Y偏移"},
    ["焦点名称"]={"焦点名称X偏移","焦点名称X偏移","焦点名称Y偏移"},
    ["目标的目标名称"]={"目标的目标名称X偏移","目标的目标名称X偏移","目标的目标名称Y偏移"},
    ["生命条"]={"生命条X偏移","生命条X偏移","生命条Y偏移"},
    ["施法条"]={"施法条X偏移","施法条X偏移","施法条Y偏移"},
    ["模型"]={"模型X偏移","模型X偏移","模型Y偏移","模型Z偏移"},
}
for noun,keys in pairs(axes)do
    for index,key in ipairs(keys)do
        if index>1 then
            local axis=({"X","Y","Z"})[index-1]
            for _,code in ipairs(codes)do
                local catalog=M.localeTables[code]
                local offset=code=="enUS"and(axis.." offset")or catalog[axis.."偏移"]
                -- Z uses the same axis wording as X/Y.
                if not offset then offset=catalog["X偏移"]:gsub("X",axis)end
                catalog[key]=catalog[noun]..(code=="zhTW"and""or" – ")..offset
            end
        end
    end
end
local aliases={
    ["正在施法"]="施法中",
    ["输入技能名称或 Spell ID，回车或离开输入框保存。未勾选手动设置距离时按技能射程判定；勾选后仅使用距离滑杆。技能为空或无法判定时不提示，旋转内环同步使用此设置。"]="按职业填写技能名称或ID，以技能射程判断距离；勾选手动距离后使用设定码数。无法判定时不提示。",
    ["头像 X 位置"]="头像X偏移",["血量条 Y"]="生命条Y偏移",
    ["宠物名字 X"]="宠物名称X偏移",["宠物名字 Y"]="宠物名称Y偏移",
    ["焦点名字 X"]="焦点名称X偏移",["焦点名字 Y"]="焦点名称Y偏移",
    ["目标的目标名字 X"]="目标的目标名称X偏移",["目标的目标名字 Y"]="目标的目标名称Y偏移",
    ["施法条 X"]="施法条X偏移",["施法条 Y"]="施法条Y偏移",
    ["模型 X"]="模型X偏移",["模型 Y"]="模型Y偏移",["模型 Z"]="模型Z偏移",
    ["字体Y偏移"]="文字Y偏移",["玻璃贴图透明度"]="玻璃透明度",
    ["仅显示头像和名字"]="仅显示头像和名称",
    ["游戏框体尚未创建，请稍后重试。"]="游戏框体尚未就绪，请稍后重试。",
    ["玩家施法条固定预览 · 点击左下角按钮在游戏画面中移动"]="点击预览视窗中的元素可调节",
    ["预览位置固定 · 点击选择元素 · 选中焦点、宠物或目标的目标框体后，可在游戏画面中移动"]="点击预览视窗中的元素可调节",
}
for source,target in pairs(aliases)do
    for _,code in ipairs(codes)do M.localeTables[code][source]=M.localeTables[code][target]end
end
-- Apply reviewed Spanish wording to both saved regional preferences.
for key,value in pairs(M.localeTables.esES)do M.localeTables.esMX[key]=value end
M:RebuildLocaleKeys()
