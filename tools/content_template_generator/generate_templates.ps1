# Generate Civilpedia Content Templates
$outputDir = "D:\Civilpedia\docs\content_template"
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

# ── Canonical Headers ──
$hTopics = @("topicId","titleAr","titleEn","categoryId","summary","tags","relatedTopicIds","createdAt","updatedAt","level","status","planKey","featuredImageUrl","simpleExplanation_ar","simpleExplanation_en","beforeWork_ar","beforeWork_en","duringWork_ar","duringWork_en","afterWork_ar","afterWork_en","siteNotes_ar","siteNotes_en","codeNotes_ar","codeNotes_en","reportWording_ar","reportWording_en","relatedToolRoutes","relatedChecklistIds","reviewedBy","approvedBy")
$hSections = @("topicId","sectionId","order","title","type")
$hBlocks = @("sectionId","order","type","text_content","text_variant","step_number","step_description","step_notes","point_criteria","point_tolerance","point_method","point_critical","safety_message","safety_severity","equipment_title","code_code","code_section","code_title","code_description","checklist_title","table_caption","image_url","image_caption")
$hChecklist = @("sectionId","blockOrder","itemId","itemText","isRequired")
$hTableRows = @("sectionId","blockOrder","rowOrder","headers","cells")
$hAccept = @("topicId","order","criteriaAr","criteriaEn","acceptanceLimitAr","acceptanceLimitEn","methodAr","methodEn","isCritical","reviewRequired")
$hMistakes = @("topicId","order","mistakeAr","mistakeEn")
$hEquipment = @("sectionId","blockOrder","itemOrder","name","purpose","specification")

# ── Arabic Guidance ──
$gTopics = @(
    "معرّف فريد للموضوع بالإنكليزية. يربط كل البيانات عبر الأوراق.",
    "عنوان الموضوع بالعربية. يظهر كعنوان رئيسي في شاشة الموضوع.",
    "عنوان الموضوع بالإنكليزية.",
    "اختر تصنيفاً: concrete, steel, soil, asphalt, general, finishing",
    "جملة تصف الموضوع. تظهر في بطاقة القائمة.",
    "كلمات مفتاحية للبحث. تفصل بفواصل.",
    "مواضيع مرتبطة (topicIds) تفصل بفواصل.",
    "تاريخ الإنشاء بصيغة ISO - اتركه للمطور.",
    "تاريخ آخر تحديث - اتركه للمطور.",
    "مستوى الموضوع: basic, intermediate, advanced",
    "حالة سير العمل: Draft, Engineering Review, Approved, Ready for App",
    "اتركه فارغاً - للاستخدام المستقبلي.",
    "رابط صورة الغلاف داخل assets/. مثال: assets/images/rebar_cover.png",
    "شرح مبسط بالعربية يظهر أعلى المقال.",
    "Simple explanation in English.",
    "تعليمات قبل البدء بالعمل بالعربية.",
    "Before-work instructions in English.",
    "شرح خطوات التنفيذ بالعربية.",
    "Execution steps in English.",
    "ما يفعله المهندس بعد الانتهاء.",
    "After-work instructions in English.",
    "ملاحظات موقعية مهمة.",
    "Site notes in English.",
    "مراجع الأكواد (ACI, ASTM) مع أرقامها.",
    "Code references in English.",
    "صياغة جاهزة لنسخها للتقرير النهائي.",
    "Report wording in English.",
    "مسارات أدوات الحاسبة (مفصولة بفواصل). مثال: /calculator/tile",
    "قوائم فحص مرتبطة - نادر الاستخدام.",
    "اسم المراجع الهندسي - اتركه للمراجع.",
    "اسم المعتمد - اتركه للمعتمد."
)
$gSections = @(
    "معرّف الموضوع الذي ينتمي إليه القسم.",
    "معرّف فريد للقسم. مثال: tile-application",
    "رقم ترتيب القسم في المقال. يبدأ من 1.",
    "عنوان القسم بالعربية.",
    "نوع القسم من: execution, inspection, safety, equipment, codeReference, general"
)
$gBlocks = @(
    "معرف القسم (sectionId) الذي ينتمي إليه هذا البلوك.",
    "ترتيب البلوك داخل القسم. يبدأ من 1.",
    "نوع البلوك. يحدد أي الأعمدة التالية تملأ: text, checklist, table, code_reference, equipment, image, safety_note, inspection_point, execution_step",
    "النص إذا كان type=text. اكتب المحتوى هنا.",
    "نوع النص: paragraph (عادي), note (ملاحظة), tip (نصيحة), warning (تحذير)",
    "رقم خطوة التنفيذ إذا كان type=execution_step.",
    "وصف خطوة التنفيذ بالعربية.",
    "ملاحظة إضافية للخطوة (اختياري).",
    "معيار نقطة الفحص إذا كان type=inspection_point.",
    "السماحية المسموحة لنقطة الفحص.",
    "طريقة الفحص المستخدمة.",
    "TRUE إذا كانت نقطة الفحص حرجة.",
    "نص تنبيه السلامة إذا كان type=safety_note.",
    "مستوى الخطورة: low, medium, high, critical",
    "عنوان مجموعة المعدات إذا كان type=equipment.",
    "رمز المرجع الهندسي إذا كان type=code_reference. مثال: ACI 318-19",
    "القسم داخل المرجع.",
    "عنوان المرجع.",
    "وصف أو ملاحظة عن المرجع.",
    "عنوان قائمة الفحص إذا كان type=checklist.",
    "عنوان الجدول إذا كان type=table. يظهر فوق الجدول.",
    "رابط الصورة إذا كان type=image.",
    "تعليق أو وصف الصورة (اختياري)."
)
$gChecklist = @(
    "معرف القسم (sectionId) الذي توجد به القائمة.",
    "رقم ترتيب البلوك (نفس الرقم في blocks.csv).",
    "معرّف فريد للبند بالإنكليزية.",
    "نص بند الفحص بالعربية.",
    "TRUE إذا كان البند إلزامياً، FALSE إذا اختياري."
)
$gTableRows = @(
    "معرف القسم (sectionId) الذي يوجد به الجدول.",
    "رقم ترتيب البلوك (نفس الرقم في blocks.csv).",
    "ترتيب الصف داخل الجدول. يبدأ من 1.",
    "رؤوس الأعمدة مفصولة بفواصل. مثال: النوع,الخامة,المقاومة",
    "قيم الصف مفصولة بفواصل. يجب تطابق ترتيبها مع رؤوس الأعمدة."
)
$gAccept = @(
    "معرف الموضوع (topicId).",
    "ترتيب البند في القائمة.",
    "معيار القبول بالعربية.",
    "Acceptance criteria in English.",
    "حد القبول المسموح بالعربية.",
    "Acceptance limit in English.",
    "طريقة الفحص بالعربية.",
    "Test method in English.",
    "TRUE إذا حرج (يظهر باللون الأحمر).",
    "TRUE إذا يحتاج مراجعة إضافية."
)
$gMistakes = @(
    "معرف الموضوع (topicId).",
    "ترتيب الخطأ في القائمة.",
    "وصف الخطأ الشائع بالعربية. يظهر للمستخدم كتحذير.",
    "Common mistake description in English."
)
$gEquipment = @(
    "معرف القسم (sectionId) الذي توجد به المعدات.",
    "رقم ترتيب البلوك (نفس الرقم في blocks.csv).",
    "ترتيب الأداة داخل القائمة. يبدأ من 1.",
    "اسم الأداة أو المعدة بالعربية.",
    "الغرض من استخدام الأداة.",
    "المواصفات الفنية للأداة (اختياري)."
)

# ── All sheets in correct order ──
$sheetNames = @("Instructions_AR","Topics","Sections","Blocks","ChecklistItems","TableRows","AcceptReject","CommonMistakes","EquipmentItems","Lists")
$sheetHeaders = @($null, $hTopics, $hSections, $hBlocks, $hChecklist, $hTableRows, $hAccept, $hMistakes, $hEquipment, $null)
$sheetGuides  = @($null, $gTopics, $gSections, $gBlocks, $gChecklist, $gTableRows, $gAccept, $gMistakes, $gEquipment, $null)
$sheetTypes   = @("instructions","data","data","data","data","data","data","data","data","lists")

# ── Lists data ──
$listsData = @(
    @("blockType","أنواع البلوكات","text, checklist, table, code_reference, equipment, image, safety_note, inspection_point, execution_step"),
    @("sectionType","أنواع الأقسام","execution, inspection, safety, equipment, codeReference, general"),
    @("level","مستوى الموضوع","basic, intermediate, advanced"),
    @("status","حالة الموضوع","Draft, Engineering Review, Approved, Ready for App"),
    @("categoryId","التصنيفات","concrete, steel, soil, asphalt, general, finishing"),
    @("textVariant","أنواع النصوص","paragraph, note, tip, warning"),
    @("safetySeverity","مستوى الخطورة","low, medium, high, critical"),
    @("trueFalse","قيم صح/خطأ","TRUE, FALSE"),
    @("toolRoute","أدوات الحاسبة","/calculator/concrete, /calculator/steel, /calculator/brick, /calculator/tile"),
    @("planKey","مفتاح الخطة","free, pro, company, supplier"),
    @("topicId","معرّف الموضوع","كلمات إنكليزية بوصلات، مثال: slump-test"),
    @("sectionId","معرّف القسم","بادئة الموضوع + واصلة + اسم، مثال: st-equipment"),
    @("blockOrder","ترتيب البلوك","يبدأ من 1 في كل قسم"),
    @("rowOrder","ترتيب الصف","يبدأ من 1 في كل بلوك جدول"),
    @("itemOrder","ترتيب الأداة","يبدأ من 1 في كل بلوك معدات")
)

# ── Instructions text ──
$instructionsLines = @(
    "Civilpedia - قالب إنتاج المحتوى الهندسي",
    "",
    "هذا القالب مخصص لإدخال المحتوى الهندسي لتطبيق Civilpedia.",
    "",
    "سير العمل:",
    "1. املأ ورقة Topics أولاً - صف واحد لكل موضوع.",
    "2. أضف أقسام الموضوع في ورقة Sections.",
    "3. أضف المحتوى التفصيلي في ورقة Blocks حسب نوع كل مقطع.",
    "4. أضف البيانات الإضافية (قوائم فحص، جداول، قبول/رفض، أخطاء شائعة، معدات) في أوراقها المخصصة.",
    "5. راجع ورقة Lists للقيم الصحيحة المدعومة.",
    "",
    "قواعد مهمة:",
    "- أسماء الأعمدة بالإنكليزية ولا تغيرها - المحول البرمجي يعتمد عليها.",
    "- المحتوى العربي هو الأساس (التطبيق عربي).",
    "- topicId يربط كل البيانات عبر الأوراق.",
    "- sectionId يربط البلوكات بالأقسام.",
    "- blockOrder يربط صفوف الجدول/قوائم الفحص/المعدات ببلوك معين.",
    "- اترك الخانات الفارغة فارغة (لا تكتب NULL أو N/A).",
    "",
    "للتصدير إلى CSV:",
    "- احذف صف التعليمات هذا.",
    "- صف الرؤوس (Headers) هو الصف الأول الذي يقرأه المحول.",
    "- صدّر كل ورقة على حدة كملف CSV.",
    "- انسخ ملفات CSV إلى المجلد content_source/.",
    "- شغّل أداة التحويل: dart run bin/convert.dart content_source ../../assets/encyclopedia/catalog.json",
    "",
    "آخر تحديث: 2026"
)

function Write-Headers {
    param($ws, $headers, $row)
    for ($c = 0; $c -lt $headers.Length; $c++) {
        $cell = $ws.Cells($row, $c+1)
        $cell.Value = $headers[$c]
        $cell.Font.Bold = $true
        $cell.Font.Size = 10
        $cell.Interior.ColorIndex = 15
        $cell.Font.ColorIndex = 2
    }
}

function Write-GuideRow {
    param($ws, $guide, $row)
    for ($c = 0; $c -lt $guide.Length; $c++) {
        $cell = $ws.Cells($row, $c+1)
        $cell.Value = $guide[$c]
        $cell.Font.Size = 10
        $cell.Font.ColorIndex = 16
        $cell.Interior.ColorIndex = 36
        $cell.WrapText = $true
    }
    $ws.Rows("${row}:${row}").RowHeight = 50
}

function New-Template {
    param($filePath, $isGuided)
    
    $wb = $excel.Workbooks.Add()
    
    for ($i = 0; $i -lt $sheetNames.Length; $i++) {
        if ($i -eq 0) {
            $ws = $wb.Worksheets(1)
        } else {
            # Add AFTER the last sheet
            $lastSheet = $wb.Worksheets($wb.Worksheets.Count)
            $ws = $wb.Worksheets.Add([System.Type]::Missing, $lastSheet)
        }
        $ws.Name = $sheetNames[$i]
        
        if ($sheetTypes[$i] -eq "instructions") {
            for ($j = 0; $j -lt $instructionsLines.Length; $j++) {
                $cell = $ws.Cells($j+1, 1)
                $cell.Value = $instructionsLines[$j]
                if ($j -eq 0) {
                    $cell.Font.Bold = $true
                    $cell.Font.Size = 16
                }
            }
            $ws.Columns("A:A").ColumnWidth = 95
            continue
        }
        
        if ($sheetTypes[$i] -eq "lists") {
            $ll = @("المرجع","الشرح","القيم المدعومة")
            Write-Headers -ws $ws -headers $ll -row 1
            for ($r = 0; $r -lt $listsData.Length; $r++) {
                $ws.Cells($r+2, 1) = $listsData[$r][0]
                $ws.Cells($r+2, 2) = $listsData[$r][1]
                $ws.Cells($r+2, 3) = $listsData[$r][2]
            }
            $ws.Columns("A:A").ColumnWidth = 22
            $ws.Columns("B:B").ColumnWidth = 30
            $ws.Columns("C:C").ColumnWidth = 85
            $ws.Activate()
            $excel.ActiveWindow.SplitRow = 1
            $excel.ActiveWindow.FreezePanes = $true
            continue
        }
        
        # Data sheet
        $hdrs = $sheetHeaders[$i]
        $gde = $sheetGuides[$i]
        
        if ($isGuided) {
            Write-GuideRow -ws $ws -guide $gde -row 1
            Write-Headers -ws $ws -headers $hdrs -row 2
            $ws.Activate()
            $excel.ActiveWindow.SplitRow = 2
        } else {
            Write-Headers -ws $ws -headers $hdrs -row 1
            $ws.Activate()
            $excel.ActiveWindow.SplitRow = 1
        }
        $excel.ActiveWindow.FreezePanes = $true
        $ws.Columns("A:A").ColumnWidth = 22
        $ws.Columns("B:Z").ColumnWidth = 18
    }
    
    $wb.SaveAs($filePath, 51)
    $wb.Close($false)
}

# ── Generate ──
Write-Output "Generating production template..."
New-Template -filePath "$outputDir\Civilpedia_Content_Production_Template.xlsx" -isGuided $false

Write-Output "Generating guided template..."
New-Template -filePath "$outputDir\Civilpedia_Content_Guided_Template.xlsx" -isGuided $true

$excel.Quit()
Write-Output "Done!"
