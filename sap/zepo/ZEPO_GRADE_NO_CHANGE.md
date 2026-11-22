# ZEPO – تحويل عمود Manufacturer Part Number إلى GRADE NO

## الشروط (يجب أن تتحقق كلها)
| الحقل | القيمة |
|---|---|
| `EKKO-BSART` (نوع المستند) | `ZEPO` |
| `EKPO-BUKRS` (الشركة) | `1700` |
| `EKPO-WERKS` (المصنع) | `1710` / `1712` / `1713` |
| `EKPO-BSTYP` (فئة المستند) | `F` |
| `EKPO-MTART` (نوع المادة) | `ZROH` / `ZPCK` |

عند تحققها:
- عنوان العمود يصبح **GRADE NO** بدل `Manufacturer Part No./ Code`
- قيمة العمود = `EKPO-BEDNR` (CHAR 10 → سعة 10 خانات)

## 1) DDIC – خطوة مطلوبة قبل التفعيل
أضف حقلًا جديدًا إلى الـ Structure **`ZMM_ST_EXTERNALPO`** (الـ HD):

| Component | Type | الوصف |
|---|---|---|
| `MFRPN_TITLE` | `CHAR40` (أو Data Element `TEXT40`) | عنوان عمود Manufacturer / GRADE NO |

ثم فعّل الـ Structure، وافتح الـ Interface في SFP وتأكد أن `HD-MFRPN_TITLE` ظاهر في الـ Context (اسحبه إلى Context الفورم إذا لم يظهر تلقائيًا).

لا تغيير على بنية الأصناف `ZMM_TT_EXTERNALPO`: القيمة تُكتب في الحقل الموجود `MFRPN`.

> تنبيه: نفس الـ Structure (`hd23`) تُمرَّر أيضًا إلى الفورمات `ZMM_F_EXTERNAL_PO_ASSET` / `_ASSET_2400` (ZAPO)
> و `ZMM_F_EXTERNAL_PO_SERVICE` (ZSPO / ZCPO). إضافة حقل جديد لا تكسرها (الحقل يبقى فارغًا ولا تستخدمه)،
> لكن جرّب طباعة أمر واحد من كل نوع بعد النقل للتأكد من إعادة توليد الـ Function Modules.

## 2) Driver ABAP (`ZMM_PO_DRIVER_MAIN.abap`، فرع `ZEPO / ZCOP / ZNPO`)
- لكل صنف داخل `SELECT ... ENDSELECT` يُقرأ `BUKRS WERKS BSTYP MTART BEDNR` من `EKPO` ويُفحص الشرط.
  - الفحص يتم **قبل** `SHIFT wa23-ebelp` لأن `EKPO-EBELP` من نوع NUMC (مثل `00010`).
- إذا تحقق الشرط: `wa23-mfrpn = EKPO-BEDNR`.
  - يتم ذلك **بعد** `SHIFT wa23-mfrpn LEFT DELETING LEADING '0'` حتى لا تُحذف الأصفار البادئة من رقم الـ Grade.
  - هذا يتجاوز منطق `MARA-MFRPN` (P03) ومنطق رقم المادة (P01/P02) للأصناف المؤهلة فقط.
- بعد الحلقة يُعبّأ `hd23-mfrpn_title`:
  - كل الأصناف مؤهلة → `GRADE NO`
  - بعضها فقط (أمر مختلط) → `Manufacturer Part No./ Code / GRADE NO`
  - لا شيء → `Manufacturer Part No./ Code` (السلوك القديم كما هو)
- `ZCOP` و `ZNPO` لا يتأثران لأن الشرط يتطلب `BSART = ZEPO`.

## 3) Layout (`ZMM_F_EXTERNALPO_TRYSH`)
- خلية العنوان الثابتة (Draw) في `TABLE.overflowLeader` استُبدلت بـ Field للقراءة فقط باسم `MFRPN_HDR`
  (Binding = None) مع Script في `initialize` يقرأ `$record.HD.MFRPN_TITLE`.
  إذا كان فارغًا يعرض العنوان القديم، فالفورم لا ينكسر حتى قبل تحديث الـ Driver.
- أُضيف `<MFRPN_TITLE/>` تحت `HD` في الـ data description.
- عمود البيانات `DATA.MFRPN` بدون تغيير (نفس العرض 27.996mm يكفي 10 خانات بخط 8pt).

## 4) اختبار مقترح
1. أمر ZEPO، شركة 1700، مصنع 1710، مادة ZROH، و`BEDNR` معبأ → العنوان `GRADE NO` والقيم = BEDNR.
2. نفس الأمر لكن مصنع 1711 أو مادة ZERS → العنوان والقيم كما كانت.
3. أمر مختلط (صنف ZROH وصنف آخر غير مؤهل) → العنوان المزدوج.
4. صنف مؤهل و`BEDNR` فارغ → الخلية فارغة (لا يرجع لـ MFRPN).
5. صفحة ثانية (overflow) → العنوان يتكرر بشكل صحيح.
6. أوامر ZCOP / ZNPO → بدون تغيير.
